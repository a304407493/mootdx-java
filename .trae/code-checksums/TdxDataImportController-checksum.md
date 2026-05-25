# TdxDataImportController.java Code Checksum

Generated: 2026-05-17

## File Info

- File path: mootdx-server\src\main\java\com\mootdx\server\controller\TdxDataImportController.java
- Total lines: 933
- Note: Run the PowerShell command below to generate actual MD5

## How to Generate MD5

```powershell
# Read the file
$File = "mootdx-server\src\main\java\com\mootdx\server\controller\TdxDataImportController.java"
$Content = Get-Content -Path $File -Raw -Encoding UTF8

# Calculate full file MD5
$Bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
$md5 = [System.Security.Cryptography.MD5]::Create()
$FullHash = [BitConverter]::ToString($md5.ComputeHash($Bytes)).Replace("-", "").ToLower()
Write-Host "Full file MD5: $FullHash"

# You can also extract specific methods and calculate their MD5
# Example:
# $Lines = $Content -split "`n"
# $MethodCode = ($Lines[114..154] -join "`n")  # scanFiles
```

## How to Verify AI Output

```powershell
# Paste AI output code here
$Code = @'
// Paste code here
'@

# Calculate MD5
$Bytes = [System.Text.Encoding]::UTF8.GetBytes($Code)
$md5 = [System.Security.Cryptography.MD5]::Create()
$Hash = [BitConverter]::ToString($md5.ComputeHash($Bytes)).Replace("-", "").ToLower()
Write-Host "MD5: $Hash"
```

## Online Verification

Visit: https://www.md5hashgenerator.com/

## Key Methods in This File

| Method Name | Approx. Line Range |
|-------------|--------------------|
| scanFiles | 115-155 |
| scanDayFiles | 455-490 |
| enrichDbInfoBatch | 493-560 |
| enrichDbInfo | 563-595 |
| scanBlockFiles | 598-640 |
| FileInfo DTO | 800-820 |

---
**Note: Run the PowerShell commands above to get actual MD5 values**
