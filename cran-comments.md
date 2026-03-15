## Release summary

* Added five new standard load profiles: `H25`, `G25`, `L25`,
  `P25`, `S25` published in 2025 by BDEW
* `slp_generate()` gains a `holidays` argument for supplying custom public
  holiday dates, replacing the deprecated `state_code` argument.
* Internal holiday data (nager.Date API, 1990–2073) refreshed.
* Bug fix: incorrect weekday assignment for Dec 24/31 falling on a Sunday
  (GitHub issue #2).

## Test environments

* local Ubuntu 24.04, R 4.3.3
* win-builder (R devel): 0 errors | 0 warnings | 1 note
* macOS builder (R 4.6.0 devel, Apple M1): 0 errors | 0 warnings | 0 notes

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Possibly misspelled words in DESCRIPTION: SLPs, Standardlastprofile, Strom
  These are domain-specific terms: SLPs is an acronym for Standard Load
  Profiles; Standardlastprofile and Strom are the German source titles cited
  in the References section.

## Reverse dependencies

None.

## Local-only issues (not expected on CRAN)

The local check produced additional notes and two warnings caused by missing
system tools (qpdf, inconsolata.sty) that are not present on this machine
but are standard on CRAN infrastructure.
