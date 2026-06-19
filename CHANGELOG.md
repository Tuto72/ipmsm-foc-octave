# Changelog

## GUI 1 — GitHub-ready Euler default

- Preserved the latest user-corrected panel geometry as the baseline.
- Kept GUI labels, button names, plot titles, comments, status messages, and error messages in English.
- Changed the default solver from RK4 to Euler.
- Kept RK4 available in the solver selector for comparison.
- Updated README and theory documentation to state that Euler is the default solver.
- Kept computation time display.
- Kept result export to MAT-file or CSV.

- ## GUI 2 - GitHub final package

- Added selectable operation mode: Basic FOC or FOC + MTPA.
- Added MTPA current-reference generation for IPMSM operation with `Lq > Ld`.
- Kept Euler as the default fixed-step solver.
- Kept RK4 as an optional fixed-step solver.
- Added computation-time display.
- Added result export as `.mat` or `.csv`.
- Added stator-current magnitude `Is` to the dq current plot.
- Updated GUI panels using the user-corrected layout.
- Updated all GUI labels, comments, and status messages to English.
- Added English and Spanish theory documents.
