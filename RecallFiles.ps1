param (
    [string]$PathList,
    [string]$RootFolder = "",
    [string[]]$CacheServers
)

# Function to display usage information
function Show-Usage {
    Write-Host "`n=== Azure File Recall Script ==="
    Write-Host "Usage:"
    Write-Host "  powershell -File RecallFiles.ps1 -PathList 'C:\Path\To\pathlist.txt' -CacheServers 'Server1','Server2' [-RootFolder '\\Server\Share']"
    Write-Host "`nParameters:"
    Write-Host "  -PathList       : Path to the file containing filenames, folders, or wildcard patterns."
    Write-Host "  -CacheServers   : List of cache servers where files should be recalled."
    Write-Host "  -RootFolder     : (Optional) Root directory for files (ignored if file paths are absolute)."
    Write-Host "`nExamples:"
    Write-Host "  powershell -File RecallFiles.ps1 -PathList 'C:\Users\ExampleUser\list.txt' -CacheServers 'NodeA','NodeB'"
    Write-Host "  powershell -File RecallFiles.ps1 -PathList '\\NetworkPath\list.txt' -CacheServers 'ServerX','ServerY' -RootFolder '\\NetworkShare\Storage'"
    exit 1
}

# Validate input parameters
if (-not $PathList -or -not (Test-Path $PathList)) {
    Write-Host "[ERROR] Path list '$PathList' not found or not specified."
    Show-Usage
}

if (-not $CacheServers) {
    Write-Host "[ERROR] No cache servers specified."
    Show-Usage
}

# Read the path list and clean up formatting
$PathEntries = Get-Content -Raw $PathList | Out-String | ForEach-Object { $_ -replace "`r`n|`r|`n", "`n" } | Out-String
$PathEntries = $PathEntries -split "`n" | Where-Object { $_ -match '\S' -and -not $_.StartsWith("#") }  # Remove empty lines & comments

Write-Host "`n=== Starting Recall Process on Cache Servers ===`n"

# Function to expand folders and wildcards
function Expand-Paths {
    param ($Path)
    
    # Convert Linux-style path to Windows format
    $Path = $Path -replace "/", "\"

    # If it's a directory, get all files inside it recursively
    if (Test-Path $Path -PathType Container) {
        return Get-ChildItem -Path $Path -Recurse -File | Select-Object -ExpandProperty FullName
    }

    # If it's a wildcard pattern, expand matching files
    elseif ($Path -match "\*|\?") {
        return Get-ChildItem -Path $Path -File | Select-Object -ExpandProperty FullName
    }

    # Otherwise, return the original file path
    return $Path
}

# Execute recall on each specified cache server
foreach ($server in $CacheServers) {
    Write-Host "[INFO] Executing recall process on: $server"

    foreach ($path in $PathEntries) {
        $path = $path.Trim('"').Trim()  # Remove leading/trailing quotes
        
        # Expand folders and wildcards into actual file paths
        $ExpandedFiles = Expand-Paths -Path $path

        foreach ($fullPath in $ExpandedFiles) {
            # Ensure paths with spaces are quoted properly
            if ($fullPath -match " ") {
                $fullPath = "`"$fullPath`""
            }

            if (Test-Path $fullPath) {
                # Get file attributes
                $fileAttributes = (Get-Item $fullPath).Attributes

                if ($fileAttributes -match "Offline") {
                    Write-Host "[INFO] Tiered file detected on $server: $fullPath"
                    # Trigger recall
                    $null = Get-Item $fullPath | Select-Object -Property Length
                    Write-Host "[INFO] Recall triggered on $server: $fullPath"
                } else {
                    Write-Host "[INFO] File already cached on $server: $fullPath"
                }
            } else {
                Write-Host "[WARNING] File not found on $server: $fullPath"
            }
        }
    }
}

Write-Host "`n=== Recall Process Completed Across All Servers ===`n"

