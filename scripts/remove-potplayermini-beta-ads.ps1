param(
	[Parameter(Mandatory = $true)][string]$Path
)

function hexToBin([string]$hex, [string]$dst) {
	if (!$dst) {
		return [System.Text.Encoding]::UTF8.GetString([byte[]]($pattern -replace '(..)', '0x$&,' -split ',' -ne ''))
	}

    if (Get-Command certutil -ErrorAction SilentlyContinue) {
        try {
            $tmp = New-TemporaryFile
            Set-Content -Path $tmp -Value $hex
            certutil -decodehex -f $tmp.FullName $dst 12 | Out-Null
            Remove-Item $tmp
            return
        } catch {
            Write-Warning "certutil failed: $($_.Exception.Message). Using fallback method."
        }
    }

	Write-Warning "Could not find certutil. Using fallback method."
    $bytesCount = $hex.Length / 2
    $bytes = New-Object byte[] $bytesCount
    for ($i = 0; $i -lt $bytesCount; $i++) {
        $bytes[$i] = [Convert]::ToByte($hex.Substring($i * 2, 2), 16)
    }
    [System.IO.File]::WriteAllBytes($dst, $bytes)
}

function fileToHex([string]$path) {
    $content = [System.IO.File]::ReadAllBytes($path)
    return [System.BitConverter]::ToString($content).replace('-','').ToUpper()
}

function replaceHex([string]$path, [hashtable]$replacements) {
    $hex = fileToHex -path $path
    $ver = (Get-Item $path).VersionInfo.FileVersion.replace(',', '.').replace(' ','')
    Write-Host ("{0} version: {1}" -f (Split-Path $path -Leaf), $ver)

    Write-Host "Replacing hex patterns..."
    $isModified = $false
    foreach ($pattern in $replacements.Keys) {
        if ($hex -match $pattern) {
            $patternShort = if ($pattern.Length -gt 10) { $pattern.Substring(0, 10) + "..." } else { $pattern }
            $patternStr = hexToBin $pattern
            Write-Host ("Found: {0} ({1})" -f $patternStr, $patternShort)
            $hex = $hex -replace $pattern, $replacements[$pattern]
            $isModified = $true
        }
    }

    if ($isModified) {
        hexToBin -hex $hex -dst $path
        Write-Host "File updated successfully."
    } else {
        Write-Warning "No patterns matched in the file."
    }
	return
}

$exePath = Join-Path -Path $Path -ChildPath "PotPlayerMini64.exe"
$dllPath = Join-Path -Path $Path -ChildPath "PotPlayer64.dll"
foreach ($p in $exePath, $dllPath) {
	if (!(Test-Path -Path $p -PathType Leaf)) {
		Write-Error "Could not find $p."
		exit 1
	}
}

$exeReplacements = [ordered]@{
    "C00F841C02000048" = "C090909090909048"
}
replaceHex -path $exePath -replacements $exeReplacements

$dllReplacements = [ordered]@{
	"000070006C00610079002E006B0061006B0061006F002E0063006F006D0000" = ""
	"000068007400740070003A002F002F00740031002E0062006500740061002E006400610075006D00630064006E002E006E00650074002F0070006F00740070006C0061007900650072002F0070006F006C006C0069006E0067002F0064006100740061002E006A0073006F006E0000" = ""
	"0000680074007400700073003A002F002F00740031002E006400610075006D00630064006E002E006E00650074002F00610064006600690074002F00680074006D006C002F00440041004E002D0076006600390070003800340061003900650035006F0036002E00680074006D006C0000" = ""
	"0000680074007400700073003A002F002F00700031002D0070006C00610079002E00650064006700650034006B002E0063006F006D002F0073007400610074007500730000" = ""
	"0000680074007400700073003A002F002F00700032002D0070006C00610079002E00650064006700650034006B002E0063006F006D002F0073007400610074007500730000" = ""
	"00680074007400700073003A002F002F00700031002D0070006C00610079002E00650064006700650034006B002E0063006F006D002F007500700064006100740065003F006C0061006E0067003D0025007300" = ""
	"00680074007400700073003A002F002F00740031002E006400610075006D00630064006E002E006E00650074002F0070006F00740070006C0061007900650072002F0050006F00740050006C006100790065007200" = ""
	"00737461742E74696172612E6B616B616F2E636F6D00" = ""
	"0073616E64626F782D737461742E74696172612E6B616B616F2E636F6D00" = ""
	"006C006900760065002D00740076002E006B0061006B0061006F002E0063006F006D00" = ""
	"00730064006B002D00740076002E006B0061006B0061006F002E0063006F006D00" = ""
	"00740076002E006B0061006B0061006F002E0063006F006D00" = ""
	"006B0061006D0070002E006B0061006B0061006F002E0063006F006D00" = ""
	"0076006100640073002D006100700069002E006400610075006D006B0061006B0061006F002E0063006F006D00" = ""
	"006300620074002D0076006100640073002D006100700069002E006400650076002E006400610075006D006B0061006B0061006F00" = ""
	"00730061006E00640062006F0078002D0076006100640073002D006100700069002E006400650076002E006400610075006D006B0061006B0061006F00" = ""
	"00730061006E00640062006F0078002D00780079006C006F00700068006F006E0065002E00610064002E006400610075006D002E006E0065007400" = ""
}
$dllKeys = $dllReplacements.Keys
for ($i = 0; $i -lt $dllKeys.Count; $i++) {
    $key = $dllKeys[$i]
    $dllReplacements[$key] = "0" * $key.Length
}

replaceHex -path $dllPath -replacements $dllReplacements
