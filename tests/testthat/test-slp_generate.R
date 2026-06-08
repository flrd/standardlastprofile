# slp_generate() is superseded by slp_electricity() (since v2.0.0). These tests
# cover the deprecation shim itself; the full behavioural suite lives in
# test-slp_electricity.R.

test_that("slp_generate() warns that it is superseded", {
  expect_warning(
    slp_generate("H0", "2026-01-01", "2026-01-07"),
    class = "lifecycle_warning_deprecated"
  )
})

test_that("slp_generate() delegates to slp_electricity() with identical output", {
  withr::local_options(lifecycle_verbosity = "quiet")
  expect_identical(
    slp_generate("H0", "2026-01-01", "2026-01-07"),
    slp_electricity("H0", "2026-01-01", "2026-01-07")
  )
  # holidays are forwarded too
  expect_identical(
    slp_generate("G0", "2026-03-01", "2026-03-07", holidays = "2026-03-04"),
    slp_electricity("G0", "2026-03-01", "2026-03-07", holidays = "2026-03-04")
  )
})

test_that("the removed state_code argument is defunct and errors (since v2.0.0)", {
  withr::local_options(lifecycle_verbosity = "quiet")
  expect_error(
    slp_generate("H0", "2026-01-01", "2026-01-07", state_code = "BE"),
    class = "lifecycle_error_deprecated"
  )
  expect_error(
    slp_generate("H0", "2026-01-01", "2026-01-07", state_code = "DE-BE"),
    class = "lifecycle_error_deprecated"
  )
})
