test_that("end_date: invalid ISO date raises an informative error", {
  expect_error(
    slp_generate("H0", start_date = Sys.Date(), end_date = "2023-13-01"),
    "'end_date' must be a valid date"
  )
})

test_that("start_date: invalid ISO date raises an informative error", {
  expect_error(
    slp_generate("H0", start_date = "2023-13-01", end_date = Sys.Date()),
    "'start_date' must be a valid date"
  )
})

test_that("start_date: two-digit year raises an error", {
  expect_error(
    slp_generate("H0", start_date = "24-01-01", end_date = "2024-12-31"),
    "'start_date' must be a valid date in ISO 8601 format"
  )
})

test_that("end_date: two-digit year raises an error", {
  expect_error(
    slp_generate("H0", start_date = "2024-01-01", end_date = "24-12-31"),
    "'end_date' must be a valid date in ISO 8601 format"
  )
})

test_that("start_date: NULL raises an informative error", {
  expect_error(
    slp_generate("H0", start_date = NULL, end_date = "2026-12-31"),
    "'start_date' is missing"
  )
})

test_that("end_date: NULL raises an informative error", {
  expect_error(
    slp_generate("H0", start_date = "2026-01-01", end_date = NULL),
    "'end_date' is missing"
  )
})

test_that("start_date: length > 1 raises an informative error", {
  expect_error(
    slp_generate(
      "H0",
      start_date = c("2026-01-01", "2026-02-01"),
      end_date = "2026-12-31"
    ),
    "'start_date' must be of length 1"
  )
})

test_that("end_date: length > 1 raises an informative error", {
  expect_error(
    slp_generate(
      "H0",
      start_date = "2026-01-01",
      end_date = c("2026-12-31", "2027-01-01")
    ),
    "'end_date' must be of length 1"
  )
})


test_that("state_code raises an error since v2.0.0", {
  expect_error(
    slp_generate(
      profile_id = "H0",
      start_date = "2026-01-01",
      end_date = "2026-01-07",
      state_code = "BE"
    ),
    "was deprecated"
  )
  expect_error(
    slp_generate(
      profile_id = "H0",
      start_date = "2026-01-01",
      end_date = "2026-01-07",
      state_code = "DE-BE"
    ),
    "was deprecated"
  )
})

test_that("holidays: non-character/Date type raises an error", {
  expect_error(
    slp_generate(
      "G0",
      "2026-01-01",
      "2026-01-01",
      holidays = list("2026-01-01")
    ),
    "'holidays' must be NA, or a character or Date vector"
  )
})

test_that("holidays: invalid dates raise an error", {
  expect_error(
    slp_generate("H0", "2024-01-01", "2024-01-07", holidays = "not-a-date"),
    "'holidays' must contain valid dates in ISO 8601 format"
  )
})

test_that("holidays: two-digit year raises an error", {
  expect_error(
    slp_generate("H0", "2024-01-01", "2024-01-01", holidays = "24-01-01"),
    "'holidays' must contain valid dates in ISO 8601 format"
  )
})

test_that("holidays: a known holiday is treated as sunday", {
  # 2024-01-01 is a Monday; with it listed as a holiday it should be 'sunday'
  with_holiday <- slp_generate(
    "G0",
    "2024-01-01",
    "2024-01-01",
    holidays = "2024-01-01"
  )
  without_holiday <- slp_generate(
    "G0",
    "2024-01-01",
    "2024-01-01",
    holidays = character(0)
  )
  expect_false(identical(with_holiday$watts, without_holiday$watts))
})

test_that("holidays: accepts Date vectors as well as character", {
  char_result <- slp_generate(
    "G0",
    "2024-03-01",
    "2024-03-07",
    holidays = "2024-03-04"
  )
  date_result <- slp_generate(
    "G0",
    "2024-03-01",
    "2024-03-07",
    holidays = as.Date("2024-03-04")
  )
  expect_equal(char_result, date_result)
})


test_that("profile_id is required", {
  expect_error(
    slp_generate(start_date = Sys.Date(), end_date = Sys.Date() + 1),
    "Please provide at least one value as 'profile_id'."
  )
})

test_that("state_code + holidays: passing state_code still errors since v2.0.0", {
  expect_error(
    slp_generate(
      "G0",
      start_date = "2026-04-01",
      end_date = "2026-06-04",
      state_code = "SL",
      holidays = "2026-04-01"
    ),
    "was deprecated"
  )
})

test_that("holidays: April 1st as custom holiday differs in 2022/2023 but not 2024", {
  # 2022-04-01 is a Friday  (workday)   → becomes Sunday with holiday
  # 2023-04-01 is a Saturday            → becomes Sunday with holiday
  # 2024-04-01 is Easter Monday         → already a built-in nationwide holiday
  #                                       (Sunday), so adding it explicitly
  #                                       changes nothing

  for (yr in c(2022L, 2023L, 2024L)) {
    date <- paste0(yr, "-04-01")
    with_hol <- slp_generate("G0", date, date, holidays = date)
    without_hol <- slp_generate("G0", date, date)

    if (yr == 2024L) {
      expect_equal(with_hol$watts, without_hol$watts)
    } else {
      expect_false(identical(with_hol$watts, without_hol$watts))
    }
  }
})

test_that("yearly calls concatenated equal a single call over the full supported range", {
  skip_on_cran()

  years <- 1990:2073

  chunks <- lapply(years, \(y) {
    slp_generate(
      "H0",
      start_date = paste0(y, "-01-01"),
      end_date = paste0(y, "-12-31")
    )
  })
  by_year <- do.call(rbind, chunks)
  row.names(by_year) <- NULL

  full <- slp_generate("H0", start_date = "1990-01-01", end_date = "2073-12-31")
  row.names(full) <- NULL

  expect_equal(by_year, full)
})
