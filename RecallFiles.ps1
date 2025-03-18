param (
    [string]$FileListPath,
    [string]$RootFolder = ""
)

# Function to display usage information
function Show-Usage {
    Write-Host "`n=== Azure File Recall Script ==="
    Write-Host "Usage:"
    Write-Host "  powershell -File RecallFiles.ps1 -FileListPath 'C:\Path\To\filelist.txt' [-RootFolder '\\Server\Share']"
    Write-Host "`nParameters:"
    Write-Host "  -FileListPath   : Path to the file list containing filenames or full file paths."
    Write-Host "  -RootFolder     : (Optional) Root directory for files (ignored if file paths are absolute)."
    Write-Host "`nExamples:"
    Write-Host "  powershell -File RecallFiles.ps1 -FileListPath 'C:\Users\User\filelist.txt'"
    Write-Host "  powershell -File RecallFiles.ps1 -FileListPath 'C:\Users\User\filelist.txt' -RootFolder '\\MyServer\AzureSyncShare'"
    Write-Host "  powershell -File RecallFiles.ps1 -FileListPath '\\Server\SharedFolder\filelist.txt' -RootFolder '\\MyServer\AzureSyncShare'"
    exit 1
}

# Validate input parameters
if (-not $FileListPath -or -not (Test-Path $FileListPath)) {
    Write-Host "[ERROR] File list '$FileListPath' not found or not specified."
    Show-Usage
}

# Read the file list and clean up formatting
$FileList = Get-Content -Raw $FileListPath | Out-String | ForEach-Object { $_ -replace "`r`n|`r|`n", "`n" } | Out-String
$FileList = $FileList -split "`n" | Where-Object { $_ -match '\S' }  # Remove empty lines

Write-Host "`n=== Starting Recall Process ===`n"

foreach ($file in $FileList) {
    # Trim spaces and remove hidden characters
    $file = $file.Trim('"').Trim()  # Remove leading/trailing quotes

    # Determine if the file is an absolute path or needs the RootFolder prepended
    if ([System.IO.Path]::IsPathRooted($file) -or $RootFolder -eq "") {
        $fullPath = $file  # File is already a full path
    } else {
        $fullPath = Join-Path -Path $RootFolder -ChildPath $file  # Use root folder
    }

    # Ensure paths with spaces are quoted properly
    if ($fullPath -match " ") {
        $fullPath = "`"$fullPath`""
    }

    if (Test-Path $fullPath) {
        # Get file attributes
        $fileAttributes = (Get-Item $fullPath).Attributes

        if ($fileAttributes -match "Offline") {
            Write-Host "[INFO] Tiered file detected: $fullPath"
            # Trigger recall
            $null = Get-Item $fullPath | Select-Object -Property Length
            Write-Host "[INFO] Recall triggered: $fullPath"
        } else {
            Write-Host "[INFO] File already cached: $fullPath"
        }
    } else {
        Write-Host "[WARNING] File not found: $fullPath"
    }
}

Write-Host "`n=== Recall Process Completed ===`n"

