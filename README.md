
# Azure File Recall Script

## Overview
This PowerShell script triggers recall of tiered files from Azure File Sync to multiple specified cache servers. It can be executed from a local machine without requiring admin rights.

## Features
- **Supports multiple cache servers**: Runs the recall process on one or more specified cache servers.
- **Handles both absolute and relative paths**: If a root folder is specified, it will prepend paths from the file list.
- **Removes unnecessary line breaks**: Ensures compatibility with file lists containing different line endings (Windows/Linux/macOS).
- **Provides real-time logging**: Displays recall status for each file and cache server.

## Usage
```
powershell -File RecallFiles.ps1 -FileListPath "C:\Path\To\filelist.txt" -CacheServers "Server1","Server2" [-RootFolder "\\Network\Share"]
```

## Parameters
| Parameter      | Description |
|-------------- |------------|
| `-FileListPath` | Path to the file containing filenames or full file paths. |
| `-CacheServers` | List of cache servers where files should be recalled. |
| `-RootFolder` | (Optional) Root directory for files (ignored if file paths are absolute). |

## Examples
### Recall files on two cache servers
```
powershell -File RecallFiles.ps1 -FileListPath "C:\Users\ExampleUser\list.txt" -CacheServers "NodeA","NodeB"
```
### Recall files with a specified root folder
```
powershell -File RecallFiles.ps1 -FileListPath "\\NetworkPath\list.txt" -CacheServers "ServerX","ServerY" -RootFolder "\\NetworkShare\Storage"
```

## How It Works
1. **Runs from your PC** and sends recall instructions to the specified cache servers.
2. **Each cache server handles the recall operation** for tiered files.
3. **The script triggers a recall** on tiered files without opening them.
4. **Results are displayed per server**, showing whether each file was already cached or successfully recalled.

## Notes
- If a file path contains spaces, the script automatically ensures proper quoting.
- The script does not require admin rights on your PC but does need permissions to execute on the cache servers.

## Troubleshooting
### Check DFS Active Server
If unsure which cache server is active for a file share, open **File Explorer**, right-click the folder, go to **Properties > DFS**, and click **Check Status**.

### Running the Script Remotely
If you do not have direct access to cache servers, use PowerShell Remoting:
```
Invoke-Command -ComputerName "ServerX" -ScriptBlock {
    powershell -File "C:\Scripts\RecallFiles.ps1" -FileListPath "C:\Scripts\list.txt"
}
```

## Conclusion
This script provides an efficient way to recall tiered files across multiple Azure File Sync cache servers. It is ideal for ensuring local availability of specific files without manual intervention.



=== Recall Process Completed ===
```


