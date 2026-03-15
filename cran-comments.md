## Release summary

* Added five new standard load profiles: `H25`, `G25`, `L25`,
  `P25`, `S25` published in 2025 by BDEW
* `slp_generate()` gains a `holidays` argument for supplying custom public
  holiday dates, replacing the deprecated `state_code` argument.
* Internal holiday data (nager.Date API, 1990–2073) refreshed.
* Bug fix: incorrect weekday assignment for Dec 24/31 falling on a Sunday
  (GitHub issue #2).

## Test environments

* local Ubuntu 24.04, R 4.4.x
* win-builder (R devel, R release)
* macOS builder (R release)

## R CMD check results

0 errors | 0 warnings | 1 note

* checking for future file timestamps ... NOTE
  unable to verify current time

## Reverse dependencies

None.

## Local-only issues (not expected on CRAN)

* checking for non-standard things in the check directory ... NOTE
  Found the following files/directories: 'standardlastprofile-manual.tex'
  Build artefact from PDF manual generation; not present on CRAN's
  check infrastructure.

* Found the following (possibly) invalid URLs: README.md → 404
  The pkgdown documentation site will be redeployed before/upon CRAN
  release; the URL will resolve once the site is live.

The local check also produced two warnings caused by missing system tools
(qpdf, inconsolata.sty) that are not present on this machine but are standard
on CRAN infrastructure. The package was additionally checked on win-builder
and macOS builder with 0 errors, 0 warnings, 0 notes.
