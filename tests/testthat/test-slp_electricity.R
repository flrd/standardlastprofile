test_that("basic call returns a data.frame with correct columns", {
  out <- slp_electricity("H0", "2026-01-01", "2026-01-07")
  expect_s3_class(out, "data.frame")
  expect_named(out, c("profile_id", "start_time", "end_time", "watts"))
  expect_equal(nrow(out), 7L * 96L)
})

test_that("multiple profile_ids are supported", {
  out <- slp_electricity(c("H0", "G0"), "2026-01-01", "2026-01-03")
  expect_equal(length(unique(out$profile_id)), 2L)
  expect_equal(nrow(out), 2L * 3L * 96L)
})

test_that("start_date: NULL raises an informative error", {
  expect_error(
    slp_electricity("H0", start_date = NULL, end_date = "2026-12-31"),
    "'start_date' is missing"
  )
})

test_that("end_date: NULL raises an informative error", {
  expect_error(
    slp_electricity("H0", start_date = "2026-01-01", end_date = NULL),
    "'end_date' is missing"
  )
})

test_that("start_date: invalid ISO date raises an error", {
  expect_error(
    slp_electricity("H0", "2026-13-01", "2026-12-31"),
    "'start_date' must be a valid date"
  )
})

test_that("end_date: invalid ISO date raises an error", {
  expect_error(
    slp_electricity("H0", "2026-01-01", "2026-13-31"),
    "'end_date' must be a valid date"
  )
})

test_that("start_date: two-digit year raises an error", {
  expect_error(
    slp_electricity("H0", "26-01-01", "2026-12-31"),
    "'start_date' must be a valid date in ISO 8601 format"
  )
})

test_that("start_date: length > 1 raises an error", {
  expect_error(
    slp_electricity("H0", c("2026-01-01", "2026-02-01"), "2026-12-31"),
    "'start_date' must be of length 1"
  )
})

test_that("no date range restriction: dates before 1990 are accepted", {
  expect_no_error(
    slp_electricity("G0", "1970-01-01", "1970-01-03")
  )
})

test_that("no date range restriction: dates after 2073 are accepted", {
  expect_no_error(
    slp_electricity("G0", "2080-01-01", "2080-01-03")
  )
})

test_that("holidays = NULL uses built-in nationwide holidays", {
  # 2026-01-01 is New Year's Day (nationwide holiday) → treated as Sunday
  with_defaults <- slp_electricity("G0", "2026-01-01", "2026-01-01")
  # without any holidays, Jan 1 2026 is a Thursday → different watts
  no_holidays <- slp_electricity(
    "G0",
    "2026-01-01",
    "2026-01-01",
    holidays = NA
  )
  expect_false(identical(with_defaults$watts, no_holidays$watts))
})

test_that("holidays = NA: no dates treated as public holidays", {
  # 2026-01-01 is a Thursday and a nationwide holiday
  # with NA, it should be treated as a plain workday (Thursday)
  out_na <- slp_electricity(
    "G0",
    "2026-01-01",
    "2026-01-01",
    holidays = NA
  )
  # explicit empty character vector should behave identically
  out_empty <- slp_electricity(
    "G0",
    "2026-01-01",
    "2026-01-01",
    holidays = character(0)
  )
  expect_equal(out_na$watts, out_empty$watts)
})

test_that("holidays = NA differs from holidays = NULL on a known holiday", {
  date <- "2026-12-25" # Christmas Day — nationwide holiday
  out_null <- slp_electricity("G0", date, date, holidays = NULL)
  out_na <- slp_electricity("G0", date, date, holidays = NA)
  expect_false(identical(out_null$watts, out_na$watts))
})

test_that("holidays: non-character/Date type raises an error", {
  expect_error(
    slp_electricity(
      "G0",
      "2026-01-01",
      "2026-01-01",
      holidays = list("2026-01-01")
    ),
    "'holidays' must be NA, or a character or Date vector"
  )
})

test_that("holidays: invalid date string raises an error", {
  expect_error(
    slp_electricity("H0", "2026-01-01", "2026-01-07", holidays = "not-a-date"),
    "'holidays' must contain valid dates in ISO 8601 format"
  )
})

test_that("holidays: accepts Date vectors as well as character", {
  char_result <- slp_electricity(
    "G0",
    "2026-03-01",
    "2026-03-07",
    holidays = "2026-03-04"
  )
  date_result <- slp_electricity(
    "G0",
    "2026-03-01",
    "2026-03-07",
    holidays = as.Date("2026-03-04")
  )
  expect_equal(char_result, date_result)
})

test_that("normalisation: H0 sums to ~1,000 kWh/a", {
  out <- slp_electricity("H0", "2026-01-01", "2026-12-31")
  expect_equal(sum(out$watts / 4 / 1000), 1000, tolerance = 1)
})
