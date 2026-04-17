# IronBook GM — Unit Testing Framework

This directory houses the structured unit testing environment for the IronBook GM project.

## Structure
- `specs/`: Contains the pure Dart logic tests (Unit tests).
- `logs/`: High-level execution logs.
- `reports/`: Human-readable test reports and status summaries.
- `results/`: Raw output from testing tools (e.g., `test_results.txt`).

## Execution
To run all unit tests and generate a report, execute:
```powershell
./execute.ps1
```

## Naming Convention
Unit tests follow the `TC-UNIT-XX` convention for tracking against the master testing framework plan in `documentation/prompts/IronBook_GM_Testing_Framework.md`.
