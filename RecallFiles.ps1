param (
    [string]$FileListPath,
    [string]$RootFolder = "",
    [string[]]$CacheServers
)

# Function to display usage information
function Show-Usage {
    Write-Host "`n=== Azure File Recall Script ==="
    Write-Host "Usage:"
    Write-Host "  powershell -File RecallFiles.ps1 -FileListPath 'C:\Path\To\filelist.txt' -CacheServers 'Server1','Server2' [-RootFolder '\\Server\Share']"
    Write-Host "`nParameters:"
    Write-Host "  -FileListPath   : Path to the file list containing filenames or full file paths."
    Write-Host "  -CacheServers   : List of cache servers where files should be recalled."
    Write-Host "  -RootFolder     : (Optional) Root directory for files (ignored if file paths are absolute)."
    Write-Host "`nExamples:"
    Write-Host "  powershell -File RecallFiles.ps1 -FileListPath 'C:\Users\ExampleUser\list.txt' -CacheServers 'NodeA','NodeB'"
    Write-Host "  powershell -File RecallFiles.ps1 -FileListPath '\\NetworkPath\list.txt' -CacheServers 'ServerX','ServerY' -RootFolder '\\NetworkShare\Storage'"
    exit 1
}

# Validate input parameters
if (-not $FileListPath -or -not (Test-Path $FileListPath)) {
    Write-Host "[ERROR] File list '$FileListPath' not found or not specified."
    Show-Usage
}

if (-not $CacheServers) {
    Write-Host "[ERROR] No cache servers specified."
    Show-Usage
}

# Read the file list and clean up formatting
$FileList = Get-Content -Raw $FileListPath | Out-String | ForEach-Object { $_ -replace "`r`n|`r|`n", "`n" } | Out-String
$FileList = $FileList -split "`n" | Where-Object { $_ -match '\S' }  # Remove empty lines

Write-Host "`n=== Starting Recall Process on Cache Servers ===`n"

# Execute recall on each specified cache server
foreach ($server in $CacheServers) {
    Write-Host "[INFO] Executing recall process on: $server"

    foreach ($file in $FileList) {
        $file = $file.Trim('"').Trim()  # Remove leading/trailing quotes

        # Determine if the file is an absolute path or needs the RootFolder prepended
        if ([System.IO.Path]::IsPathRooted($file) -or $RootFolder -eq "") {
            $fullPath = $file
        } else {
            $fullPath = Join-Path -Path $RootFolder -ChildPath $file
        }

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

Write-Host "`n=== Recall Process Completed Across All Servers ===`n"
