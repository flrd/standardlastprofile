test_that("end_date expects a ISO date", {
  expect_error(
    slp_generate(
      profile_id = "H0",
      start_date = Sys.Date(),
      end_date = "2023-13-01"
    ),
    "Please provide a valid date in ISO 8601 format"
  )
})

test_that("start_date expects a ISO date", {
  expect_error(
    slp_generate(
      profile_id = "H0",
      start_date = "2023-13-01",
      end_date = Sys.Date()
    ),
    "Please provide a valid date in ISO 8601 format"
  )
})

test_that("start_date must be greater 1973", {
  expect_error(
    slp_generate(
      profile_id = "H0",
      start_date = "1972-12-31",
      end_date = Sys.Date()
    ),
    "Date range must be between 1990-01-01 and 2073-12-31."
  )
})

test_that("start_date must be greater 1973", {
  expect_error(
    slp_generate(
      profile_id = "H0",
      start_date = Sys.Date(),
      end_date = "2074-01-01"
    ),
    "Date range must be between 1990-01-01 and 2073-12-31."
  )
})

test_that("deprecated state_code: 'BE' and 'DE-BE' produce same result", {
  expect_warning(
    out_short <- slp_generate(
      profile_id = "H0",
      start_date = "2023-12-01",
      end_date = "2024-12-01",
      state_code = "BE"
    ),
    "deprecated"
  )
  expect_warning(
    out_full <- slp_generate(
      profile_id = "H0",
      start_date = "2023-12-01",
      end_date = "2024-12-01",
      state_code = "DE-BE"
    ),
    "deprecated"
  )
  expect_equal(out_short, out_full)
})

test_that("holidays: invalid dates raise an error", {
  expect_error(
    slp_generate("H0", "2024-01-01", "2024-01-07", holidays = "not-a-date"),
    "'holidays' must contain valid dates in ISO 8601 format."
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

test_that("yearly calls concatenated equal a single call over the full supported range", {
  skip_on_cran()

  years <- 1990:2073

  chunks <- lapply(years, function(y) {
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
