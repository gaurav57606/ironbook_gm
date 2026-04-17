# IronBook GM — Unit Test Executor

$project_dir = ".."
$test_dir = "specs"
$results_dir = "results"
$logs_file = "logs/execution.log"

Write-Host "Running IronBook GM Unit Tests (Pure Logic)..." -ForegroundColor Cyan

# Ensure we are in the project folder
Push-Location $project_dir

# Run flutter test on the specs directory
# We redirect output to the results folder
flutter test unit_test/$test_dir --reporter expanded > unit_test/$results_dir/test_results.txt 2>&1

$exitCode = $LASTEXITCODE

Pop-Location

if ($exitCode -eq 0) {
    Write-Host "All Unit Tests PASSED!" -ForegroundColor Green
    Add-Content -Path $logs_file -Value "$(Get-Date): All tests passed."
} else {
    Write-Host "Some tests FAILED. Check unit_test/results/test_results.txt for details." -ForegroundColor Red
    Add-Content -Path $logs_file -Value "$(Get-Date): Tests failed with exit code $exitCode."
}

exit $exitCode
