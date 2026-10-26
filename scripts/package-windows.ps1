[CmdletBinding()]
param([switch]$SkipBuild)
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root
$Identity = Get-Content 'packaging/windows/identity.json' -Raw | ConvertFrom-Json
$Pubspec = Get-Content 'pubspec.yaml' -Raw
if ($Pubspec -notmatch '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$') { throw 'Cannot read version from pubspec.yaml' }
$Version = $Matches[1]
if (-not $SkipBuild) {
  & flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed' }
  & flutter build windows --release
  if ($LASTEXITCODE -ne 0) { throw 'Windows compilation failed' }
}
$Bundle = Join-Path $Root 'build/windows/x64/runner/Release'
if (-not (Test-Path "$Bundle/CipherVault.exe")) { throw 'Windows bundle missing' }
$Out = Join-Path $Root 'artifacts/windows'
New-Item -ItemType Directory -Force $Out | Out-Null
$Stage = Join-Path $Out 'staging'
if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
New-Item -ItemType Directory -Force $Stage | Out-Null
Copy-Item "$Bundle/*" $Stage -Recurse -Force
foreach ($File in @('LICENSE','PRIVACY.md','SECURITY.md','THIRD_PARTY.md')) { Copy-Item (Join-Path $Root $File) $Stage }
# Ship the licensed app-local MSVC CRT instead of assuming a global installation.
$VSWhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
$VS = & $VSWhere -latest -products '*' -property installationPath
if (-not $VS) { throw 'Visual Studio installation not found' }
$CRT = Get-ChildItem "$VS/VC/Redist/MSVC/*/x64/Microsoft.VC*.CRT" -Directory | Sort-Object FullName -Descending | Select-Object -First 1
if (-not $CRT) { throw 'Redistributable MSVC runtime not found' }
Copy-Item "$($CRT.FullName)/*.dll" $Stage -Force
$Zip = Join-Path $Out "CipherVault_${Version}_windows_x64.zip"
Compress-Archive -Path "$Stage/*" -DestinationPath $Zip -Force
$Assets = Join-Path $Stage 'Assets'
New-Item -ItemType Directory -Force $Assets | Out-Null
Add-Type -AssemblyName System.Drawing
$Source = [System.Drawing.Image]::FromFile((Join-Path $Root 'assets/images/logo.png'))
try {
  foreach ($Spec in @(@('StoreLogo.png',50),@('Square44x44Logo.png',44),@('Square150x150Logo.png',150))) {
    $Size = [int]$Spec[1]
    $Image = New-Object System.Drawing.Bitmap($Size,$Size)
    $Graphics = [System.Drawing.Graphics]::FromImage($Image)
    try {
      $Graphics.Clear([System.Drawing.Color]::Transparent)
      $Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $Graphics.DrawImage($Source,0,0,$Size,$Size)
      $Image.Save((Join-Path $Assets $Spec[0]),[System.Drawing.Imaging.ImageFormat]::Png)
    } finally { $Graphics.Dispose(); $Image.Dispose() }
  }
} finally { $Source.Dispose() }
function XmlEscape([string]$Value) { return [System.Security.SecurityElement]::Escape($Value) }
$Name = XmlEscape $Identity.name
$Publisher = XmlEscape $Identity.publisher
$Display = XmlEscape $Identity.displayName
$PublisherDisplay = XmlEscape $Identity.publisherDisplayName
$Manifest = @"
<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10" xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10" xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities" IgnorableNamespaces="uap rescap">
  <Identity Name="$Name" Publisher="$Publisher" Version="$Version.0" ProcessorArchitecture="x64"/>
  <Properties><DisplayName>$Display</DisplayName><PublisherDisplayName>$PublisherDisplay</PublisherDisplayName><Logo>Assets\StoreLogo.png</Logo></Properties>
  <Resources><Resource Language="tr-tr"/><Resource Language="en-us"/></Resources>
  <Dependencies><TargetDeviceFamily Name="Windows.Desktop" MinVersion="10.0.19041.0" MaxVersionTested="10.0.26100.0"/></Dependencies>
  <Applications><Application Id="CipherVault" Executable="CipherVault.exe" EntryPoint="Windows.FullTrustApplication"><uap:VisualElements DisplayName="$Display" Description="Offline encrypted password vault" BackgroundColor="#0D1119" Square44x44Logo="Assets\Square44x44Logo.png" Square150x150Logo="Assets\Square150x150Logo.png"/></Application></Applications>
  <Capabilities><rescap:Capability Name="runFullTrust"/></Capabilities>
</Package>
"@
[System.IO.File]::WriteAllText((Join-Path $Stage 'AppxManifest.xml'),$Manifest,[System.Text.UTF8Encoding]::new($false))
$MakeAppx = Get-ChildItem "${env:ProgramFiles(x86)}/Windows Kits/10/bin/*/x64/makeappx.exe" | Sort-Object FullName -Descending | Select-Object -First 1
if (-not $MakeAppx) { throw 'Windows SDK MakeAppx not found' }
$MSIX = Join-Path $Out "CipherVault_${Version}_x64-store.msix"
& $MakeAppx.FullName pack /d $Stage /p $MSIX /o
if ($LASTEXITCODE -ne 0) { throw 'MSIX package validation failed' }
$Sums = foreach ($File in @($Zip,$MSIX)) { (Get-FileHash $File -Algorithm SHA256).Hash.ToLowerInvariant() + '  ' + (Split-Path $File -Leaf) }
[System.IO.File]::WriteAllLines((Join-Path $Out 'SHA256SUMS-Windows.txt'),$Sums,[System.Text.UTF8Encoding]::new($false))
Write-Output "Prepared $Zip and $MSIX. Store signing and certification are separate."
