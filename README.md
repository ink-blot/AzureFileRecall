
# Azure File Recall Script

## 📌 Overview
This PowerShell script triggers the recall (download) of tiered files from Azure Files using **Azure File Sync**. It scans a **file list** and attempts to download files **that exist as stubs** (tiered but not cached locally). 

If a file is already cached, it will be skipped. If a file is missing, a warning will be logged.

## 🚀 Usage

### **Basic Command**
```powershell
powershell -File RecallFiles.ps1 -FileListPath "C:\Path\To\filelist.txt"
```
- This checks for tiered files listed in `filelist.txt` and recalls them.

### **Using a Network Share**
```powershell
powershell -File RecallFiles.ps1 -FileListPath "C:\Path\To\filelist.txt" -RootFolder "\\MyServer\AzureSyncShare"
```
- If the file list contains filenames without paths, this prepends `\\MyServer\AzureSyncShare\` to each file.

### **Using a Mapped Drive**
```powershell
net use Z: \\MyServer\AzureSyncShare
powershell -File RecallFiles.ps1 -FileListPath "C:\Path\To\filelist.txt" -RootFolder "Z:\"
```

### **Using a Network File List**
If the file list is stored on a network share:
```powershell
powershell -File RecallFiles.ps1 -FileListPath "\\Server\SharedFolder\filelist.txt" -RootFolder "\\MyServer\AzureSyncShare"
```
This allows `filelist.txt` to be stored centrally while recalling files from a different network share.

## 📄 File List Format
- The `filelist.txt` can contain **either filenames or full file paths**. Example:
  ```
  DJI_0001.JPG
  Survey_01.TIF
  \\MyServer\AzureSyncShare\Mapping_02.JPG
  \\MyServer\AzureSyncShare\Thermal_01.PNG
  ```

## 🔹 How It Works
1. Reads filenames from `filelist.txt`.
2. If a **RootFolder** is provided, it **prepends** it to filenames (unless they are absolute paths).
3. **If a file is tiered**, triggers recall.
4. **If a file is already cached**, skips it.
5. **If a file is missing**, logs a warning.

## ✅ Output Messages
| Message | Meaning |
|---------|---------|
| `[INFO] Tiered file detected: <filepath>` | File is a stub and will be recalled. |
| `[INFO] Recall triggered: <filepath>` | File download was requested. |
| `[INFO] File already cached: <filepath>` | File is already stored locally. |
| `[WARNING] File not found: <filepath>` | File does not exist in the local cache. |

## ⚠️ Requirements
- **PowerShell** (Windows 10/11 or Windows Server)
- **Azure File Sync** configured on the target server.
- **Read & Write permissions** to the file share.

## 📌 Example Output
```
=== Starting Recall Process ===

[INFO] Tiered file detected: \\MyServer\AzureSyncShare\DJI_0001.JPG
[INFO] Recall triggered: \\MyServer\AzureSyncShare\DJI_0001.JPG

[INFO] File already cached: \\MyServer\AzureSyncShare\Survey_01.TIF

[WARNING] File not found: \\MyServer\AzureSyncShare\missing_file.jpg

=== Recall Process Completed ===
```


