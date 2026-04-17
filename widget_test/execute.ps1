# IronBook GM Widget Test Execution Script
# TC-PHASE-02 (Widget Testing)

$resultsDir = "results"
$resultsFile = "$resultsDir/test_results.txt"
$startTime = Get-Date

if (!(Test-Path $resultsDir)) {
    New-Item -ItemType Directory -Path $resultsDir
}

Write-Host "Running IronBook GM Widget Tests (UI Components)..." -ForegroundColor Cyan

# Run widget tests from the specs directory
# We use flutter test and point it to the specs/ folder
flutter test specs/ > $resultsFile 2>&1

$endTime = Get-Date
$duration = $endTime - $startTime
$content = Get-Content $resultsFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "All Widget Tests PASSED!" -ForegroundColor Green
} else {
    Write-Host "Some tests FAILED. Check widget_test/results/test_results.txt for details." -ForegroundColor Red
}

# Prepend metadata to the results file
$header = @"
Created At: $($startTime.ToString("yyyy-MM-ddTHH:mm:ssZ"))
Completed At: $($endTime.ToString("yyyy-MM-ddTHH:mm:ssZ"))
Duration: $($duration.TotalSeconds.ToString("F2"))s
"@

$newContent = $header + "`n`n" + ($content -join "`n")
Set-Content $resultsFile $newContent
