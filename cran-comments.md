## Release summary

This is a major update (2.0.0) of an existing CRAN package. The headline
feature is support for **gas** standard load profiles alongside the existing
electricity profiles.

New functionality:

* `slp_gas()` generates daily gas standard load profiles using the
  BDEW/VKU/GEODE synthetic procedure (SigLinDe method).
* `slp_gas_kundenwert()` derives the customer value (Kundenwert) from a
  reference temperature series.
* `slp_gas_siglinde()`, `slp_gas_coefficients()`, and
  `slp_gas_weekday_factors()` expose the underlying SigLinDe function,
  coefficients, and weekday factors.
* `slp_electricity()` is the new primary function for electricity profiles,
  with on-the-fly nationwide public-holiday computation (no longer capped by a
  precomputed table).
* `slp_info()` now also describes gas profile IDs.

Renames and deprecations (all backward compatible — see below):

* The dataset `slp` has been renamed to `slp_electricity_profiles`.
* `slp_generate()` is superseded by `slp_electricity()`.

## Backward compatibility

The renamed dataset and superseded function continue to work:

* Accessing the old dataset name `slp` still returns the data and emits a
  `lifecycle` deprecation warning pointing to `slp_electricity_profiles`.
* `slp_generate()` remains available and forwards to `slp_electricity()`.

## Test environments

* local: Ubuntu 24.04, R 4.6.0 — 0 errors | 0 warnings | 0 notes
* macOS builder (macOS 26.2, R 4.6.0 Patched, Apple M1) — 0 errors |
  0 warnings | 0 notes
* win-builder, R-release (4.6.0) — 1 NOTE (see below)
* win-builder, R-devel (2026-06-06 r90114) — 1 NOTE (see below)

## R CMD check results

0 errors | 0 warnings | 1 note.

The only NOTE comes from the CRAN incoming feasibility check on win-builder:

* "Possibly misspelled words in DESCRIPTION: VKU" — VKU is the acronym of an
  industry association (Verband kommunaler Unternehmen) and a co-author of the
  cited source. It is spelled correctly, and is also listed in `inst/WORDLIST`.

As a new major version (2.0.0), the incoming-feasibility check also notes the
maintainer address, which is expected.

## Reverse dependencies

None.

## Local-only issues (not expected on CRAN)

When run locally, the check may emit additional notes/warnings caused by
missing system tools (e.g. qpdf) that are standard on CRAN infrastructure but
not installed on this machine.
