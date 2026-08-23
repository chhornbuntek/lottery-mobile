param(
  [string]$Branch = ""
)

Set-Location $PSScriptRoot\..

if ($Branch) {
  dart run tool/prepare_branch.dart $Branch
} else {
  dart run tool/prepare_branch.dart
}

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

flutter build apk --release
