# MD5 Checksum Generator
param(
    [string]$TargetFile = "..\mootdx-server\src\main\java\com\mootdx\server\controller\TdxDataImportController.java",
    [string]$OutputDir = "..\.trae\code-checksums"
)

Write-Host "MD5 Checksum Generator"
Write-Host "------------------------"

# Check if file exists
if (-not (Test-Path $TargetFile)) {
    Write-Host "Error: File not found $TargetFile"
    exit 1
}

# Read file content
$FileContent = Get-Content -Path $TargetFile -Raw -Encoding UTF8
$Lines = $FileContent -split "`n"

Write-Host "File: $TargetFile"
Write-Host "Total lines: $($Lines.Count)"

# Create MD5 object
$md5 = [System.Security.Cryptography.MD5]::Create()

# Calculate MD5 for complete file
$FileBytes = [System.Text.Encoding]::UTF8.GetBytes($FileContent)
$FullMD5 = [BitConverter]::ToString($md5.ComputeHash($FileBytes)).Replace("-", "").ToLower()

Write-Host "Full MD5: $FullMD5"
Write-Host ""

# Define key methods
$KeyMethods = @(
    @{ Name = "scanFiles"; StartLine = 114; EndLine = 154 },
    @{ Name = "scanDayFiles"; StartLine = 454; EndLine = 489 },
    @{ Name = "enrichDbInfoBatch"; StartLine = 492; EndLine = 559 },
    @{ Name = "enrichDbInfo"; StartLine = 562; EndLine = 594 },
    @{ Name = "scanBlockFiles"; StartLine = 597; EndLine = 639 },
    @{ Name = "FileInfo DTO"; StartLine = 799; EndLine = 819 }
)

Write-Host "Key Methods:"
Write-Host ""

$MethodResults = @()

foreach ($Method in $KeyMethods) {
    if ($Method.StartLine -lt $Lines.Count -and $Method.EndLine -lt $Lines.Count) {
        $MethodCode = ($Lines[$Method.StartLine..$Method.EndLine] -join "`n")
        $MethodBytes = [System.Text.Encoding]::UTF8.GetBytes($MethodCode)
        $MethodMD5 = [BitConverter]::ToString($md5.ComputeHash($MethodBytes)).Replace("-", "").ToLower()
        
        Write-Host "  $($Method.Name)"
        Write-Host "    Lines: $($Method.StartLine+1)-$($Method.EndLine+1)"
        Write-Host "    MD5: $MethodMD5"
        Write-Host ""
        
        $MethodResults += @{
            Name = $Method.Name
            StartLine = $Method.StartLine + 1
            EndLine = $Method.EndLine + 1
            MD5 = $MethodMD5
        }
    }
}

# Generate output file
$FileName = Split-Path $TargetFile -Leaf
$BaseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
$OutputFile = Join-Path $OutputDir "$($BaseName)-checksum.md"

$ManifestContent = "# $FileName Code Checksum`n`n"
$ManifestContent += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n`n"
$ManifestContent += "## File Info`n`n"
$ManifestContent += "- File path: $TargetFile`n"
$ManifestContent += "- Total lines: $($Lines.Count)`n"
$ManifestContent += "- Full MD5: \`$FullMD5\``n`n"
$ManifestContent += "## Key Methods Checksums`n`n"
$ManifestContent += "| Method Name | Line Range | MD5 Hash |`n"
$ManifestContent += "|-------------|------------|----------|`n"

foreach ($Result in $MethodResults) {
    $ManifestContent += "| $($Result.Name) | $($Result.StartLine)-$($Result.EndLine) | \`$($Result.MD5)\` |`n"
}

$ManifestContent += "`n## How to Verify`n`n"
$ManifestContent += "```powershell`n"
$ManifestContent += "`$Code = @'`n"
$ManifestContent += "// Paste code here`n"
$ManifestContent += "'@`n"
$ManifestContent += "`$Bytes = [System.Text.Encoding]::UTF8.GetBytes(`$Code)`n"
$ManifestContent += "`$md5 = [System.Security.Cryptography.MD5]::Create()`n"
$ManifestContent += "`$Hash = [BitConverter]::ToString(`$md5.ComputeHash(`$Bytes)).Replace('-', '').ToLower()`n"
$ManifestContent += "Write-Host 'MD5:' `$Hash`n"
$ManifestContent += "```"

$ManifestContent | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "Checksum saved to: $OutputFile"
Write-Host "Done!"
