param(
  [Parameter(Mandatory = $true)]
  [string] $Cling,

  [Parameter(Mandatory = $true)]
  [string] $TestFile,

  [Parameter(Mandatory = $true)]
  [string] $OutputDirectory,

  [Parameter(Mandatory = $true)]
  [string] $RunLabel,

  [string[]] $ClingArguments = @(),

  [int] $TimeoutSeconds = 60
)

$ErrorActionPreference = 'Stop'

$clingPath = (Resolve-Path -LiteralPath $Cling).Path
$testPath = (Resolve-Path -LiteralPath $TestFile).Path
$testInput = Get-Content -LiteralPath $testPath -Raw
New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
$outputPath = (Resolve-Path -LiteralPath $OutputDirectory).Path

$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $clingPath
foreach ($argument in $ClingArguments) {
  $startInfo.ArgumentList.Add($argument)
}
$startInfo.ArgumentList.Add($testPath)
$startInfo.WorkingDirectory = (Get-Location).Path
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true

$process = [System.Diagnostics.Process]::new()
$process.StartInfo = $startInfo
if (-not $process.Start()) {
  throw "Failed to start $clingPath"
}

$stdoutTask = $process.StandardOutput.ReadToEndAsync()
$stderrTask = $process.StandardError.ReadToEndAsync()

$timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
if ($timedOut) {
  $process.Kill($true)
  $process.WaitForExit()
}

$stdout = $stdoutTask.GetAwaiter().GetResult()
$stderr = $stderrTask.GetAwaiter().GetResult()
$exitCode = $process.ExitCode
$transcript = @"
run: $RunLabel
command: $clingPath $($ClingArguments -join ' ') $testPath
timeout-seconds: $TimeoutSeconds
timed-out: $timedOut
exit-code: $exitCode

=== input ===
$testInput
=== stdout ===
$stdout
=== stderr ===
$stderr
"@

$transcript | Set-Content "$outputPath/transcript.txt" -Encoding utf8NoBOM
Write-Host $transcript

$hasPassMarker = ($stdout + $stderr).Contains('CLING_WINDOWS_EMUTLS_PASS')
$passed = -not $timedOut -and $exitCode -eq 0 -and $hasPassMarker
$status = if ($passed) { 'PASS' } else { 'FAIL' }
@"
# $RunLabel

- Status: $status
- Exit code: $exitCode
- Timed out: $timedOut
- Pass marker found: $hasPassMarker
"@ | Set-Content "$outputPath/summary.md" -Encoding utf8NoBOM

if (-not $passed) {
  exit 1
}

exit 0
