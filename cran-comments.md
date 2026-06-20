## Release summary

This is a patch update (2.0.1) of an existing CRAN package.

Changes since 2.0.0:

* Updated the BDEW gas *Leitfaden* reference URL; the previous link returned a
  404. References now point to the current edition (KoV XV, 2026-03-27) via a
  stable Internet Archive permalink. The SigLinDe coefficients and method are
  unchanged.
* `slp_gas()`, `slp_gas_kundenwert()`, and `slp_gas_coefficients()` now also
  accept numeric `34` or `33` for the `variant` argument (in addition to
  character `"34"` / `"33"`).
* Added input validation for `slp_gas_siglinde()` coefficients and for
  out-of-range temperatures in `slp_gas()` / `slp_gas_kundenwert()`.

No user-visible changes to existing behaviour; `slp_generate()` and `slp` remain
deprecated (with warnings), as in 2.0.0.

## Test environments

* local: Ubuntu 24.04, R 4.6.0 — 0 errors | 0 warnings | 0 notes

## R CMD check results

0 errors | 0 warnings | 0 notes.

## Reverse dependencies

None.
