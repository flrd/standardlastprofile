# slp_generate() is defunct since v2.1.0. These tests cover the shim itself;
# the full behavioural suite lives in test-slp_electricity.R.

test_that("slp_generate() errors with a defunct message", {
  expect_error(
    slp_generate("H0", "2026-01-01", "2026-01-07"),
    "slp_generate.*defunct|slp_electricity",
    ignore.case = TRUE
  )
})

test_that("slp_generate() errors regardless of arguments passed", {
  expect_error(
    slp_generate("H0", "2026-01-01", "2026-01-07", state_code = "BE"),
    "slp_generate.*defunct|slp_electricity",
    ignore.case = TRUE
  )
  expect_error(
    slp_generate("H0", "2026-01-01", "2026-01-07", holidays = "2026-01-01"),
    "slp_generate.*defunct|slp_electricity",
    ignore.case = TRUE
  )
})
