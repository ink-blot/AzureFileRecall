param (
    [string]$PathList,
    [string]$RootFolder = "",
    [string]$LogFile = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)\RecallFiles.log"
)

# Clear the log file if it exists
Set-Content -Path $LogFile -Value "" -ErrorAction SilentlyContinue

# Function to log messages to both console and log file
function Log-Message {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogFile -Value $logEntry
}

# Function to display usage information
function Show-Usage {
    Log-Message "`n=== Azure File Recall Script ==="
    Log-Message "Usage:"
    Log-Message "  powershell -File RecallFiles.ps1 -PathList 'C:\Path\To\pathlist.txt' [-RootFolder '\\Server\Share'] [-LogFile 'C:\Logs\output.log']"
    Log-Message "`nParameters:"
    Log-Message "  -PathList       : Path to the file containing filenames, folders, or wildcard patterns."
    Log-Message "  -RootFolder     : (Optional) Root directory for files (ignored if file paths are absolute)."
    Log-Message "  -LogFile        : (Optional) Path to log file (default: script directory)."
    Log-Message "`nExamples:"
    Log-Message "  powershell -File RecallFiles.ps1 -PathList 'C:\Users\ExampleUser\list.txt'"
    Log-Message "  powershell -File RecallFiles.ps1 -PathList '\\NetworkPath\list.txt' -RootFolder '\\NetworkShare\Storage' -LogFile 'C:\Logs\output.log'"
    exit 1
}

# Debug: Print input parameters
Log-Message "[DEBUG] PathList: $PathList"
Log-Message "[DEBUG] RootFolder: $RootFolder"
Log-Message "[DEBUG] LogFile: $LogFile"

# Validate input parameters
if (-not $PathList -or -not (Test-Path -LiteralPath $PathList)) {
    if (-not $RootFolder) {
        Log-Message "[ERROR] Either -PathList or -RootFolder must be specified."
        Show-Usage
    }
    Log-Message "[INFO] No PathList provided. Using RootFolder as the path."
    $PathEntries = @($RootFolder)  # Treat RootFolder as the path
} else {
    Log-Message "[INFO] Using provided PathList."
    # Read the path list and clean up formatting
    $PathEntries = Get-Content -Raw $PathList | Out-String | ForEach-Object { $_ -replace "`r`n|`r|`n", "`n" } | Out-String
    $PathEntries = $PathEntries -split "`n" | Where-Object { $_ -match '\S' -and -not $_.StartsWith("#") }  # Remove empty lines & comments
}



# Read the path list and clean up formatting
$PathEntries = Get-Content -Raw $PathList | Out-String | ForEach-Object { $_ -replace "`r`n|`r|`n", "`n" } | Out-String
$PathEntries = $PathEntries -split "`n" | Where-Object { $_ -match '\S' -and -not $_.StartsWith("#") }  # Remove empty lines & comments

Log-Message "`n=== Starting Recall Process on Local Machine ===`n"

# Function to expand folders and wildcards
function Expand-Paths {
    param ($Path)

    # Convert Linux-style path to Windows format
    $Path = $Path -replace "/", "\\"

    # If RootFolder is specified and the path is relative, prepend it
    if ($RootFolder -and -not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path -Path $RootFolder -ChildPath $Path
    }

    # Debugging output
    Log-Message "[DEBUG] Processing path: $Path"

    # Separate base directory and wildcard (if present)
    $BaseDir = [System.IO.Path]::GetDirectoryName($Path)
    $Wildcard = [System.IO.Path]::GetFileName($Path)
    
    # If it's a directory, get all files inside it recursively
    if (Test-Path -LiteralPath $BaseDir -PathType Container) {
        Log-Message "[DEBUG] Expanding folder: $BaseDir"
        return Get-ChildItem -Path (Join-Path -Path $BaseDir -ChildPath $Wildcard) -Recurse -File | Select-Object -ExpandProperty FullName   
    }
    
    # If no wildcard, return the direct path
    Log-Message "[DEBUG] Using direct path: $Path"
    return $Path
}

foreach ($path in $PathEntries) {
    $path = $path.Trim('"').Trim()  # Remove leading/trailing quotes
    
    # Expand folders and wildcards into actual file paths
    $ExpandedFiles = Expand-Paths -Path $path

    foreach ($fullPath in $ExpandedFiles) {

        # Convert to an absolute path
        $fullPath = [System.IO.Path]::GetFullPath($fullPath)

        # Convert to long UNC path format if it exceeds 260 characters
        if ($fullPath.Length -ge 260) {
            $fullPath = '\\\\?\\UNC' + $fullPath.Substring(1)
        }

        # Debugging output
        Log-Message "[DEBUG] Checking file: $fullPath"

        # Use Resolve-Path before Test-Path to prevent false negatives
        $resolvedPath = Resolve-Path -LiteralPath $fullPath -ErrorAction SilentlyContinue

        if ($resolvedPath) {
            Log-Message "[INFO] File exists: $resolvedPath"

            # Get file attributes
            $fileItem = Get-Item -LiteralPath $resolvedPath
            $fileAttributes = $fileItem.Attributes

            # Decode attributes into readable format
            $attributeNames = [System.Enum]::GetValues([System.IO.FileAttributes]) | Where-Object { ($fileAttributes -band $_) -eq $_ }
            $attributeString = ($attributeNames -join ", ")

            # Print out file attributes
            Log-Message "[DEBUG] File attributes: $attributeString"

            if ($fileAttributes -band [System.IO.FileAttributes]::Offline) {
                Log-Message "[INFO] Tiered file detected: $resolvedPath"

                # Convert to a proper Windows file path
                $fsutilPath = Convert-Path -LiteralPath $resolvedPath

                # Trigger recall using a partial read
                Log-Message "[DEBUG] Attempting recall by reading file: $fsutilPath"

                try {
                    $stream = [System.IO.File]::OpenRead($fsutilPath)
                    $buffer = New-Object byte[] 8192  # Read first 8KB instead of 4KB
                    #$buffer = New-Object byte[] $stream.Length  # Read full file size #Read full file
                    $stream.Read($buffer, 0, $buffer.Length) | Out-Null
                    $stream.Close()

                    Log-Message "[INFO] Recall initiated: $fsutilPath"
                } catch {
                    Log-Message "[ERROR] Recall failed for: $fsutilPath. Error: $_"
                }

                # Wait for file to fully recall
                $timeout = 300  # Max wait time in seconds (5 minutes)
                $elapsed = 0

                while ($true) {
                    Start-Sleep -Seconds 10  # Add a delay between checks
                    $fileItem = Get-Item -LiteralPath $resolvedPath
                    $fileAttributes = $fileItem.Attributes
                    $attributeNames = [System.Enum]::GetValues([System.IO.FileAttributes]) | Where-Object { ($fileAttributes -band $_) -eq $_ }
                    $attributeString = ($attributeNames -join ", ")
                    
                    Log-Message "[DEBUG] Checking recall status: $attributeString"

                    if ($fileAttributes -band [System.IO.FileAttributes]::Offline) {
                        Log-Message "[DEBUG] File still offline, waiting..."
                    } else {
                        Log-Message "[INFO] File successfully recalled: $fsutilPath"
                        break
                    }

                    $elapsed += 2  # Since we're sleeping for 2 seconds per iteration
                    if ($elapsed -ge $timeout) {
                        Log-Message "[WARNING] File recall timeout: $fsutilPath"
                        break
                    }
                }

                # Small delay before moving to next file (prevents throttling)
                Start-Sleep -Milliseconds 500
            } else {
                Log-Message "[INFO] File already cached: $resolvedPath"
            }


        } else {
            Log-Message "[WARNING] File not found: $fullPath"
        }



    }
}

Log-Message "`n=== Recall Process Completed ===`n"


