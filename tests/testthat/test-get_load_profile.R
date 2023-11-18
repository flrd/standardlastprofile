test_that("end_date expects a ISO date", {
  expect_error(
    get_load_profile(
      profiles = "H0",
      start_date = Sys.Date(),
      end_date = "2023-13-01"
    ),
    "Please provide a valid date in ISO 8601 format"
  )
})

test_that("start_date expects a ISO date", {
  expect_error(
    get_load_profile(
      profiles = "H0",
      start_date = "2023-13-01",
      end_date = Sys.Date()
      ),
      "Please provide a valid date in ISO 8601 format"
    )
})

test_that("start_date must be greater 1973", {
  expect_error(
    get_load_profile(
      profiles = "H0",
      start_date = "1972-12-31",
      end_date = Sys.Date()
    ),
    "Supported date range must be between 1973-01-01 and 2073-12-31."
  )
})

test_that("start_date must be greater 1973", {
  expect_error(
    get_load_profile(
      profiles = "H0",
      start_date = Sys.Date(),
      end_date = "2074-01-01"
    ),
    "Supported date range must be between 1973-01-01 and 2073-12-31."
  )
})
