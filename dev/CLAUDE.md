# CLAUDE.md

- Ask clarifying questions before making architectural changes.
- Read <https://www.bdew.de/energie/standardlastprofile-strom/> to
  familiarize yourself with business logic of R package
  standardlastprofile
- Follow Hadley Wickhamn’s tidy design principles:
  <https://design.tidyverse.org/>
- Carefully check code for potential bugs and think about edge case that
  could make the algorithm break
- Prefer British spelling over American spelling

## Project

standardlastprofile is R data package providing BDEW (German
energy/water industry association) Standard Load Profiles (SLPs) for
electricity — representative consumption patterns for different customer
groups in the German electricity market.

## Common Commands

All commands are run from within R or via `Rscript`:

``` r
# Load package for interactive development
devtools::load_all()

# Run all tests
devtools::test()

# Run a single test file
testthat::test_file("tests/testthat/test-geom-pointless.R")

# Regenerate documentation from roxygen2 comments
devtools::document()

# Full R CMD check
devtools::check()

# Build pkgdown documentation site
pkgdown::build_site()

# Code coverage
covr::package_coverage()
```

To update visual snapshots (vdiffr), run:

``` r
vdiffr::manage_cases()
```

## Documentation site (pkgdown)

- Articles live in `vignettes/articles/` (website-only;
  `^vignettes/articles$` is in `.Rbuildignore`, so they are NOT built
  into the package and ship no vignettes).
- pkgdown 2.2.0 maps `vignettes/articles/<name>.Rmd` to the **flat**
  output `docs/articles/<name>.html` (confirm via
  `pkgdown::as_pkgdown(".")$vignettes$file_out`). The navbar/index link
  to the flat path, so that is the canonical, served page.
- To iterate on one article, use
  `pkgdown::build_article("articles/<name>")` (fast; it edits exactly
  `docs/articles/<name>.html`). Avoid the slow full `build_site()` for
  quick previews — and note `build_site()`/`build_articles()` write the
  **same flat path**, they do not nest.
- **Do NOT be confused by `docs/articles/articles/<name>.html`.** Those
  ~300-byte files are pkgdown **redirect stubs** (`<meta refresh>` →
  `../<name>.html`) that forward old nested URLs to the canonical flat
  page; pkgdown regenerates them, so leave them alone. (Historically
  they were full stale pages from an *older* pkgdown that nested the
  `articles/` subdir; pkgdown 2.x replaced them with redirects. If you
  ever see a *full-size* file there, it’s stale cruft safe to delete.)
- When editing an article and “nothing changes” in the browser: you are
  almost certainly viewing a different output file or a cached copy —
  rebuild with `build_article` and open `docs/articles/<name>.html`
  directly, hard-refresh (Ctrl+Shift+R).

## Architecture

- as of version 1.0.0 the package uses base R functions in the core
  logic to have no dependencies

**Key Algorithm Details (slp_generate)**

1.  Maps each date in the range to a period (winter/summer/transition)
    and weekday (workday/saturday/sunday)
2.  Looks up the corresponding 96-value column from an internal matrix
    per profile
3.  For H0 only: applies a polynomial dynamization function that scales
    consumption by day-of-year (higher in winter)
4.  Public holidays → treated as Sunday; Dec 24 & 31 → treated as
    Saturday (unless Sunday)
5.  Output is normalised to ~1,000 kWh/year

**Internal Data**

- load_profiles_lst: pre-built matrices for fast lookup
- holidays_de(years): nationwide German public holidays computed on the
  fly via the Anonymous Gregorian Easter algorithm; covers 1990 onward
  (the year German Unity Day became a federal holiday). No precomputed
  table is shipped.

## Testing

Tests use **testthat** (3rd edition) and **vdiffr** for visual
regression tests. Snapshot files live in `tests/testthat/_snaps/`. CI
runs R CMD check across macOS, Windows, and Ubuntu (R
devel/release/oldrel-1) via `.github/workflows/R-CMD-check.yaml`.
