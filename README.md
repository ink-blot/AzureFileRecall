# Azure File Recall Script

## Overview

This PowerShell script recalls files from an Azure storage system by checking file availability and triggering a recall process if necessary. It supports scanning directories recursively and handling wildcard paths.

## Usage

The script can be executed using **PowerShell** or **Windows CMD**. You can specify either:

- A **RootFolder** to scan all files in a directory.
- A **PathList** file containing specific paths or wildcard patterns.
- Both **RootFolder** and **PathList** together.

The instructions below show the script location is 

### **1. Running with just a RootFolder (simplest usage)**

This will scan all files recursively in the specified directory:

#### **PowerShell:**

```powershell
\\Path\To\RecallFiles.ps1 -RootFolder "\\Path\To\DataFolder"
```

#### **Windows CMD:**

```cmd
powershell -File \\Path\To\RecallFiles.ps1 -RootFolder "\\Path\To\DataFolder"
```

### **2. Running with a PathList file**

If you have a text file containing a list of file paths or wildcard patterns, specify it using `-PathList`.

#### **PowerShell:**

```powershell
\\Path\To\RecallFiles.ps1 -PathList "\\Path\To\pathlist.txt"
```

#### **Windows CMD:**

```cmd
powershell -File \\Path\To\RecallFiles.ps1 -PathList "\\Path\To\pathlist.txt"
```

### **3. Running with Both PathList and RootFolder**

You can combine both options to prepend the specified directory path to relative paths or wild cards specified in the PathList:

#### **PowerShell:**

```powershell
\\Path\To\RecallFiles.ps1 -PathList "\\Path\To\pathlist.txt" -RootFolder "\\Path\To\DataFolder"
```

#### **Windows CMD:**

```cmd
powershell \\Path\To\RecallFiles.ps1 -PathList "\\Path\To\pathlist.txt" -RootFolder "\\Path\To\DataFolder"
```

### **4. Specifying a Log File**

By default, logs are saved as `RecallFiles.log` in the script's directory. You can specify a custom log file location:

#### **PowerShell:**

```powershell
\\Path\To\RecallFiles.ps1 -RootFolder "\\Path\To\DataFolder" -LogFile "\\Path\To\output.log"
```

#### **Windows CMD:**

```cmd
powershell \\Path\To\RecallFiles.ps1 -RootFolder "\\Path\To\DataFolder" -LogFile "\\Path\To\output.log"
```

## Notes

- The script supports **wildcard characters** (`*`, `?`) in file paths within the `-PathList` file.
- If both `-PathList` and `-RootFolder` are specified, `-PathList` takes precedence but will still scan under `-RootFolder` if paths are relative.
- Long UNC paths are automatically converted if they exceed 260 characters.

## Example PathList.txt

Example of a `pathlist.txt` file:

```
*.tif
Subfolder\*.jpg
SpecificFile.txt
```

This would:

1. Match all `.tif` files in the specified `-RootFolder`.
2. Match all `.jpg` files in `Subfolder`.
3. Check for `SpecificFile.txt` in the `-RootFolder`.

---

### **End of README**




