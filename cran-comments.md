## Release summary

This is a patch update (2.0.1) of an existing CRAN package.

Changes since 2.0.0:

* Updated the BDEW reference URLs; the previous links returned a 404.
  References now point to the current edition via a stable Internet
  Archive permalink. 
* Added input validation for `slp_gas_siglinde()` coefficients and for
  out-of-range temperatures in `slp_gas()` / `slp_gas_kundenwert()`.

No user-visible changes to existing behaviour.

## Test environments

* local: Ubuntu 24.04, R 4.6.0 — 0 errors | 0 warnings | 0 notes
* win-builder: R-devel (R Under development, 2026-06-19 r90183) — Status: OK
* win-builder: R-release (R 4.6.0) — Status: OK
* macOS builder (mac.r-project.org): R-release 4.6.0,
  aarch64-apple-darwin (Apple M1) — Status: OK

## R CMD check results

0 errors | 0 warnings | 0 notes.

## Reverse dependencies

None.
