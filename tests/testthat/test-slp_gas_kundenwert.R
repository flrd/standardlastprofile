# Full-year synthetic reference temperature series (deterministic, no random noise)
dates_ref <- seq.Date(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "day")
doy_ref <- as.integer(format(dates_ref, "%j"))
temps_ref <- 10 - 11 * cos(2 * pi * (doy_ref - 15) / 365)

# Short series for warning tests
dates_week <- seq.Date(as.Date("2026-01-05"), as.Date("2026-01-11"), by = "day")
temps_week <- c(2.1, -1.3, 0.5, 3.8, 5.2, 4.0, 1.9)

test_that("returns a named numeric vector for a single profile", {
  kw <- slp_gas_kundenwert("HEF", dates_ref, temps_ref)
  expect_type(kw, "double")
  expect_length(kw, 1L)
  expect_named(kw, "HEF")
})

test_that("multiple profiles return a named vector of matching length", {
  kw <- slp_gas_kundenwert(c("HEF", "GKO", "GWA"), dates_ref, temps_ref)
  expect_length(kw, 3L)
  expect_named(kw, c("HEF", "GKO", "GWA"))
})

test_that("KW values are positive for standard inputs", {
  kw <- slp_gas_kundenwert(c("HEF", "GKO"), dates_ref, temps_ref)
  expect_true(all(kw > 0))
})

test_that("KW scales linearly with annual_consumption", {
  kw_1k <- slp_gas_kundenwert(
    "HEF",
    dates_ref,
    temps_ref,
    annual_consumption = 1000
  )
  kw_10k <- slp_gas_kundenwert(
    "HEF",
    dates_ref,
    temps_ref,
    annual_consumption = 10000
  )
  expect_equal(kw_10k, kw_1k * 10, tolerance = 1e-10)
})

test_that("KW * sum(h * F_WT) equals annual_consumption", {
  annual <- 12345
  kw <- slp_gas_kundenwert(
    "HEF",
    dates_ref,
    temps_ref,
    annual_consumption = annual,
    holidays = NA
  )
  q_total <- sum(
    slp_gas("HEF", dates_ref, temps_ref, kundenwert = kw, holidays = NA)$kwh
  )
  expect_equal(q_total, annual, tolerance = 1e-6)
})

test_that("variant '33' and '34' produce different KW values", {
  kw_34 <- slp_gas_kundenwert("HEF", dates_ref, temps_ref, variant = "34")
  kw_33 <- slp_gas_kundenwert("HEF", dates_ref, temps_ref, variant = "33")
  expect_false(identical(kw_34, kw_33))
})

test_that("HKO KW is identical for variant 33 and 34", {
  kw_34 <- slp_gas_kundenwert("HKO", dates_ref, temps_ref, variant = "34")
  kw_33 <- slp_gas_kundenwert("HKO", dates_ref, temps_ref, variant = "33")
  expect_equal(kw_34, kw_33)
})

test_that("message is issued for series shorter than 365 days", {
  expect_message(
    slp_gas_kundenwert("HEF", dates_week, temps_week),
    "only meaningful when derived from a full reference year"
  )
})

test_that("no message for a full 365-day series", {
  expect_no_message(slp_gas_kundenwert("HEF", dates_ref, temps_ref))
})

test_that("no message for a 366-day leap year series", {
  dates_leap <- seq.Date(
    as.Date("2024-01-01"),
    as.Date("2024-12-31"),
    by = "day"
  )
  doy_leap <- as.integer(format(dates_leap, "%j"))
  temps_leap <- 10 - 11 * cos(2 * pi * (doy_leap - 15) / 366)
  expect_no_message(slp_gas_kundenwert("HEF", dates_leap, temps_leap))
})

test_that("profile_id: invalid value raises an error", {
  expect_error(
    slp_gas_kundenwert("H0", dates_ref, temps_ref),
    "'profile_id' should be one of"
  )
})

test_that("dates: non-Date/character type raises an error", {
  expect_error(
    slp_gas_kundenwert("HEF", 1:366, temps_ref),
    "'dates' must be a Date vector or character vector"
  )
})

test_that("dates and temperatures: mismatched lengths raise an error", {
  expect_error(
    slp_gas_kundenwert("HEF", dates_ref, c(1, 2)),
    "must have the same length"
  )
})

test_that("dates and temperatures: only one supplied raises an error", {
  expect_error(
    slp_gas_kundenwert("HEF", dates = dates_ref),
    "must both be supplied or both be NULL"
  )
  expect_error(
    slp_gas_kundenwert("HEF", temperatures = temps_ref),
    "must both be supplied or both be NULL"
  )
})

test_that("temperatures: NA raises an error", {
  bad <- temps_ref
  bad[3] <- NA_real_
  expect_error(slp_gas_kundenwert("HEF", dates_ref, bad), "must not contain NA")
})

test_that("annual_consumption: non-positive value raises an error", {
  expect_error(
    slp_gas_kundenwert("HEF", dates_ref, temps_ref, annual_consumption = 0),
    "'annual_consumption' must be a single finite positive numeric value"
  )
})

test_that("annual_consumption: NA raises an informative error", {
  expect_error(
    slp_gas_kundenwert(
      "HEF",
      dates_ref,
      temps_ref,
      annual_consumption = NA_real_
    ),
    "'annual_consumption' must be a single finite positive numeric value"
  )
})

test_that("applying the derived KW over the reference year reproduces E_a", {
  # slp_gas_kundenwert() default annual_consumption is 1000; applying that KW
  # back over the same series with slp_gas() must reproduce 1000 kWh.
  kw <- slp_gas_kundenwert("GKO", dates_ref, temps_ref, holidays = NA)
  q_kw <- slp_gas("GKO", dates_ref, temps_ref, kundenwert = kw, holidays = NA)
  expect_equal(sum(q_kw$kwh), 1000, tolerance = 1e-6)
})

test_that("holidays: invalid date string raises an error", {
  expect_error(
    slp_gas_kundenwert("HEF", dates_ref, temps_ref, holidays = "not-a-date"),
    "'holidays' must contain valid dates in ISO 8601 format"
  )
})

test_that("error when neither dates nor temperatures is supplied", {
  expect_error(
    slp_gas_kundenwert("HEF"),
    "Please supply 'dates' and 'temperatures'"
  )
})
