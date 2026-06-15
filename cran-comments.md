## Release summary

This is a minor update (2.1.0) of an existing CRAN package.

Changes since 2.0.0:

* `slp_generate()` is now **defunct** — calling it raises an error. Use
  `slp_electricity()` instead.
* The `slp` dataset alias is now **defunct** — accessing it raises an error.
  Use `slp_electricity_profiles` instead.
* The `lifecycle` package dependency has been removed; the package now has no
  runtime dependencies.
* `slp_gas_coefficients()`, `slp_gas_kundenwert()`, and `slp_gas()` now also
  accept numeric `34` or `33` for the `variant` argument (in addition to
  character `"34"` / `"33"`).

## Backward compatibility

`slp_generate()` and `slp` were deprecated in 2.0.0 with warnings pointing to
their replacements. They are now defunct and raise errors, as is standard
practice for the deprecation lifecycle.

## Test environments

* local: Ubuntu 24.04, R 4.6.0 — 0 errors | 0 warnings | 0 notes

## R CMD check results

0 errors | 0 warnings | 0 notes.

## Reverse dependencies

None.
