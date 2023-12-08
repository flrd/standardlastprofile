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

test_that("user can supply 'BE' and 'DE-BE' as state_code", {
  expect_equal(
    slp_generate(
      profile_id = "H0",
      start_date = "2023-12-01",
      end_date = "2024-12-01",
      state_code = "BE"
    ),
    slp_generate(
      profile_id = "H0",
      start_date = "2023-12-01",
      end_date = "2024-12-01",
      state_code = "DE-BE"
    )
  )
})

test_that("profile_id is required", {
  expect_error(slp_generate(start_date = Sys.Date(), end_date = Sys.Date() + 1),
               "Please provide at least one value as 'profile_id'.")
})
