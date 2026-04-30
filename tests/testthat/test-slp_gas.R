dates_week <- seq.Date(as.Date("2026-01-05"), as.Date("2026-01-11"), by = "day")
temps_week <- c(2.1, -1.3, 0.5, 3.8, 5.2, 4.0, 1.9)

test_that("basic call returns a data.frame with correct columns", {
  out <- suppressWarnings(slp_gas(
    "HEF",
    dates_week,
    temps_week,
    annual_consumption = 1000
  ))
  expect_s3_class(out, "data.frame")
  expect_named(out, c("profile_id", "date", "kwh"))
  expect_equal(nrow(out), 7L)
})

test_that("multiple profile_ids are supported and output is stacked", {
  out <- suppressWarnings(slp_gas(
    c("HEF", "GKO"),
    dates_week,
    temps_week,
    annual_consumption = 1000
  ))
  expect_equal(nrow(out), 14L)
  expect_equal(sort(unique(out$profile_id)), c("GKO", "HEF"))
})

test_that("kwh values are positive", {
  out <- suppressWarnings(slp_gas(
    "HEF",
    dates_week,
    temps_week,
    annual_consumption = 1000
  ))
  expect_true(all(out$kwh > 0))
})

test_that("short temperature series without kundenwert warns", {
  expect_warning(
    slp_gas("HEF", dates_week, temps_week, annual_consumption = 1000),
    "only meaningful over a full reference year"
  )
})

test_that("no warning when kundenwert is supplied directly", {
  expect_no_warning(slp_gas("HEF", dates_week, temps_week, kundenwert = 5))
})

test_that("annual_consumption scales output proportionally", {
  out_1k <- suppressWarnings(slp_gas(
    "HEF",
    dates_week,
    temps_week,
    annual_consumption = 1000
  ))
  out_10k <- suppressWarnings(slp_gas(
    "HEF",
    dates_week,
    temps_week,
    annual_consumption = 10000
  ))
  expect_equal(out_10k$kwh, out_1k$kwh * 10, tolerance = 1e-10)
})

test_that("kundenwert overrides annual_consumption", {
  out_kw <- slp_gas("HEF", dates_week, temps_week, kundenwert = 5)
  out_annl <- suppressWarnings(slp_gas(
    "HEF",
    dates_week,
    temps_week,
    annual_consumption = 99999
  ))
  expect_false(identical(out_kw$kwh, out_annl$kwh))
  # with fixed kundenwert the sum equals kw * sum(h * F)
  out_null <- slp_gas("HEF", dates_week, temps_week, kundenwert = 1)
  expect_true(all(out_kw$kwh == out_null$kwh * 5))
})

test_that("dates: non-Date/character type raises an error", {
  expect_error(
    slp_gas("HEF", 1:7, temps_week),
    "'dates' must be a Date vector or character vector"
  )
})

test_that("dates: empty vector raises an error", {
  expect_error(
    slp_gas("HEF", as.Date(character(0)), numeric(0)),
    "'dates' must contain at least one element"
  )
})

test_that("dates: NA raises an error", {
  bad_dates <- dates_week
  bad_dates[3] <- NA
  expect_error(slp_gas("HEF", bad_dates, temps_week), "must not contain NA")
})

test_that("dates: invalid ISO 8601 string raises an error", {
  expect_error(
    slp_gas("HEF", "not-a-date", 2.0),
    "ISO 8601"
  )
})

test_that("dates: character vector in ISO 8601 is accepted", {
  expect_equal(
    suppressWarnings(slp_gas(
      "HEF",
      as.character(dates_week),
      temps_week,
      annual_consumption = 1000
    ))$kwh,
    suppressWarnings(slp_gas(
      "HEF",
      dates_week,
      temps_week,
      annual_consumption = 1000
    ))$kwh
  )
})

test_that("temperatures: non-numeric type raises an error", {
  expect_error(
    slp_gas("HEF", dates_week, as.character(temps_week)),
    "'temperatures' must be a numeric vector"
  )
})

test_that("temperatures: NA raises an error", {
  bad_temps <- temps_week
  bad_temps[3] <- NA_real_
  expect_error(slp_gas("HEF", dates_week, bad_temps), "must not contain NA")
})

test_that("temperatures: -Inf raises an error", {
  bad_temps <- temps_week
  bad_temps[1] <- -Inf
  expect_error(slp_gas("HEF", dates_week, bad_temps), "finite")
})

test_that("temperatures: Inf raises an error", {
  bad_temps <- temps_week
  bad_temps[1] <- Inf
  expect_error(slp_gas("HEF", dates_week, bad_temps), "finite")
})

test_that("dates and temperatures: mismatched lengths raise an error", {
  expect_error(
    slp_gas("HEF", dates_week, c(1, 2)),
    "must have the same length"
  )
})

test_that("temperatures: temp >= 40 raises an error", {
  expect_error(
    slp_gas("HEF", as.Date("2026-07-15"), 40, annual_consumption = 1000),
    "pole temperature"
  )
})

test_that("profile_id: invalid value raises an error", {
  expect_error(
    slp_gas("H0", dates_week, temps_week),
    "'profile_id' should be one of"
  )
})

test_that("kundenwert: negative value raises an error", {
  expect_error(
    slp_gas("HEF", dates_week, temps_week, kundenwert = -1),
    "'kundenwert' must be a single finite non-negative numeric value"
  )
})

test_that("kundenwert = 0 is accepted and produces zero kwh", {
  out <- slp_gas("HEF", dates_week, temps_week, kundenwert = 0)
  expect_true(all(out$kwh == 0))
})

test_that("kundenwert: NA raises an informative error", {
  expect_error(
    slp_gas("HEF", dates_week, temps_week, kundenwert = NA_real_),
    "'kundenwert' must be a single finite non-negative numeric value"
  )
})

test_that("kundenwert: NaN raises an informative error", {
  expect_error(
    slp_gas("HEF", dates_week, temps_week, kundenwert = NaN),
    "'kundenwert' must be a single finite non-negative numeric value"
  )
})

test_that("kundenwert: Inf raises an informative error", {
  expect_error(
    slp_gas("HEF", dates_week, temps_week, kundenwert = Inf),
    "'kundenwert' must be a single finite non-negative numeric value"
  )
})

test_that("annual_consumption: non-positive value raises an error", {
  expect_error(
    slp_gas("HEF", dates_week, temps_week, annual_consumption = -1),
    "'annual_consumption' must be a single finite positive numeric value"
  )
})

test_that("annual_consumption: NA raises an informative error", {
  expect_error(
    slp_gas("HEF", dates_week, temps_week, annual_consumption = NA_real_),
    "'annual_consumption' must be a single finite positive numeric value"
  )
})

test_that("annual_consumption: Inf raises an informative error", {
  expect_error(
    slp_gas("HEF", dates_week, temps_week, annual_consumption = Inf),
    "'annual_consumption' must be a single finite positive numeric value"
  )
})

test_that("annual_consumption = NULL is accepted when kundenwert is supplied", {
  out <- slp_gas(
    "HEF",
    dates_week,
    temps_week,
    kundenwert = 5,
    annual_consumption = NULL
  )
  expect_s3_class(out, "data.frame")
  expect_true(all(out$kwh > 0))
})

test_that("annual_consumption = NULL raises an error when kundenwert is NULL", {
  expect_error(
    slp_gas("HEF", dates_week, temps_week, annual_consumption = NULL),
    "Please supply either"
  )
})

test_that("message when both kundenwert and annual_consumption are supplied", {
  .pkg_env <- standardlastprofile:::.pkg_env
  .pkg_env[["slp_gas_kw_overrides_ac"]] <- NULL
  expect_message(
    slp_gas(
      "HEF",
      dates_week,
      temps_week,
      kundenwert = 5,
      annual_consumption = 1000
    ),
    "kundenwert.*annual_consumption.*ignored"
  )
  # second call: no message (once per session)
  expect_no_message(
    slp_gas(
      "HEF",
      dates_week,
      temps_week,
      kundenwert = 5,
      annual_consumption = 1000
    )
  )
})

test_that("holidays: NA_character_ raises an informative error", {
  expect_error(
    slp_gas(
      "HEF",
      dates_week,
      temps_week,
      annual_consumption = 1000,
      holidays = NA_character_
    ),
    "Use `holidays = NA`"
  )
})

test_that("holidays: character vector containing NA raises an informative error", {
  expect_error(
    slp_gas(
      "HEF",
      dates_week,
      temps_week,
      annual_consumption = 1000,
      holidays = c("2026-01-01", NA_character_)
    ),
    "Use `holidays = NA`"
  )
})

test_that("holidays = NULL uses built-in nationwide holidays", {
  # 2026-01-01 is New Year's Day (Thursday); with built-in holidays it gets
  # Sunday weekday factor; without any holidays it gets Thursday factor.
  # GKO has different F_WT per weekday so this must produce different kwh.
  d <- as.Date("2026-01-01")
  out_null <- suppressWarnings(slp_gas(
    "GKO",
    d,
    2.0,
    annual_consumption = 1000,
    holidays = NULL
  ))
  out_na <- suppressWarnings(slp_gas(
    "GKO",
    d,
    2.0,
    annual_consumption = 1000,
    holidays = NA
  ))
  expect_false(identical(out_null$kwh, out_na$kwh))
})

test_that("holidays = NA: no dates treated as public holidays", {
  d <- as.Date("2026-01-01")
  out_na <- suppressWarnings(slp_gas(
    "GKO",
    d,
    2.0,
    annual_consumption = 1000,
    holidays = NA
  ))
  out_empty <- suppressWarnings(slp_gas(
    "GKO",
    d,
    2.0,
    annual_consumption = 1000,
    holidays = character(0)
  ))
  expect_equal(out_na$kwh, out_empty$kwh)
})

test_that("holidays: a supplied date is treated as Sunday", {
  # 2026-01-05 is a Monday; supplying it as a holiday gives the Sunday factor.
  # Use a fixed kundenwert so KW does not cancel the weekday factor difference.
  d <- as.Date("2026-01-05")
  with_holiday <- slp_gas(
    "GKO",
    d,
    2.0,
    kundenwert = 1,
    holidays = "2026-01-05"
  )
  without_holiday <- slp_gas("GKO", d, 2.0, kundenwert = 1, holidays = NA)
  expect_false(identical(with_holiday$kwh, without_holiday$kwh))
})

test_that("holidays: invalid date string raises an error", {
  expect_error(
    slp_gas(
      "HEF",
      dates_week,
      temps_week,
      annual_consumption = 1000,
      holidays = "not-a-date"
    ),
    "'holidays' must contain valid dates in ISO 8601 format"
  )
})

test_that("holidays: non-character/Date type raises an error", {
  expect_error(
    slp_gas(
      "HEF",
      dates_week,
      temps_week,
      annual_consumption = 1000,
      holidays = list("2026-01-01")
    ),
    "'holidays' must be NA, or a character or Date vector"
  )
})

test_that("HEF weekday factors are all 1: day-of-week has no effect", {
  # For HEF (and HMF, HKO) all F_WT = 1, so two days with identical
  # temperature but different weekdays must produce the same kwh.
  expect_equal(
    slp_gas(
      "HEF",
      as.Date("2026-01-05"),
      5.0,
      kundenwert = 1,
      holidays = NA
    )$kwh,
    slp_gas(
      "HEF",
      as.Date("2026-01-11"),
      5.0,
      kundenwert = 1,
      holidays = NA
    )$kwh
  )
})

test_that("GKO weekday factors differ: Monday vs Sunday gives different kwh", {
  expect_false(identical(
    slp_gas(
      "GKO",
      as.Date("2026-01-05"),
      5.0,
      kundenwert = 1,
      holidays = NA
    )$kwh,
    slp_gas(
      "GKO",
      as.Date("2026-01-11"),
      5.0,
      kundenwert = 1,
      holidays = NA
    )$kwh
  ))
})

test_that("variant '33' and '34' produce different results", {
  out_34 <- slp_gas(
    "HEF",
    dates_week,
    temps_week,
    kundenwert = 1,
    variant = "34"
  )
  out_33 <- slp_gas(
    "HEF",
    dates_week,
    temps_week,
    kundenwert = 1,
    variant = "33"
  )
  expect_false(identical(out_34$kwh, out_33$kwh))
})

test_that("variant defaults to '34'", {
  out_default <- slp_gas("HEF", dates_week, temps_week, kundenwert = 1)
  out_34 <- slp_gas(
    "HEF",
    dates_week,
    temps_week,
    kundenwert = 1,
    variant = "34"
  )
  expect_equal(out_default$kwh, out_34$kwh)
})

test_that("variant: invalid value raises an error", {
  expect_error(
    slp_gas("HEF", dates_week, temps_week, kundenwert = 1, variant = "35"),
    "should be one of"
  )
})

test_that("HKO kwh is identical for variant 33 and 34", {
  out_34 <- slp_gas(
    "HKO",
    dates_week,
    temps_week,
    kundenwert = 1,
    variant = "34"
  )
  out_33 <- slp_gas(
    "HKO",
    dates_week,
    temps_week,
    kundenwert = 1,
    variant = "33"
  )
  expect_equal(out_34$kwh, out_33$kwh)
})
