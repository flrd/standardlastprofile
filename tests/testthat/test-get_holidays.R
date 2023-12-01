# holidays of state Berlin in 2023
berlin_23 <-
  c(
    "2023-01-01",
    "2023-04-07",
    "2023-04-10",
    "2023-05-01",
    "2023-05-18",
    "2023-05-29",
    "2023-10-03",
    "2023-12-25",
    "2023-12-26"
  )


test_that("multiplication works", {
  expect_equal(get_holidays(holidays_DE, years = 2023, state_code = "DE-BE"), berlin_23)
})
