# php extension installer

param (
    [string]$ExtName,
    [string]$PhpBin= "php",
    [string]$ExtPath = "."
)

$scriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition
. "$scriptPath\logger.ps1" -ToolName "install"

info "Start installing php extension"
$origwd = (Get-Location).Path
Set-Location $ExtPath

$phppath = ((Get-Command $PhpBin).Source | Select-String -Pattern '(.+)\\php\.exe').Matches.Groups[1].Value
$extpath = "$phppath\ext"
$inipath = "$phppath\php.ini"

if(-Not (Test-Path "$env:BUILD_DIR\php_$ExtName.dll" -PathType Leaf)){
    err "Could not found $env:BUILD_DIR\php_$ExtName.dll, do we running in env.bat?"
    Set-Location $origwd
    exit 1
}

info "Copy $env:BUILD_DIR\php_$ExtName.dll to $extpath"
Copy-Item "$env:BUILD_DIR\php_$ExtName.dll" $ExtPath | Out-Null

try{
    $ini = Get-Content $inipath
}catch{
    $ini = ""
}

if(($ini | Select-String -Pattern ('^\s*extension\s*=\s*["' + "'" + "]*$ExtName['" + '"' + ']*\s*')).Matches){
    warn "Ini entry extension=$ExtName is already setted, skipping ini modification"
}else{
    info ('Append "extension=' + $ExtName + '" to ' + $inipath)
    $content = "
extension=$ExtName
"
    $content | Out-File -Encoding utf8 -Append $inipath
}
info "Run 'php --ri $ExtName'"
& $PhpBin --ri $ExtName

Set-Location $origwd
