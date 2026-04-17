# IronBook GM Integration Test Execution Script
# Purpose: Run all E2E integration tests and generate reports

$test_dir = "specs"
$results_dir = "results"

if (-not (Test-Path $results_dir)) {
    New-Item -ItemType Directory -Path $results_dir | Out-Null
}

Write-Host "--- Running IronBook GM Integration Tests (E2E Flows) ---" -ForegroundColor Cyan

$all_passed = $true

# Find all test files
$test_files = Get-ChildItem -Path $test_dir -Filter "*_test.dart"

foreach ($file in $test_files) {
    Write-Host "Testing $($file.Name)..." -NoNewline
    
    # Run integration test
    # Note: Requires a connected device or emulator
    flutter test integration_test/specs/$($file.Name) > "$results_dir/$($file.BaseName)_output.txt" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host " PASSED" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        $all_passed = $false
    }
}

if ($all_passed) {
    Write-Host "`nAll Integration Tests PASSED!" -ForegroundColor Green
} else {
    Write-Host "`nSome Integration Tests FAILED. Check results/ for logs." -ForegroundColor Red
}

exit ($all_passed ? 0 : 1)
