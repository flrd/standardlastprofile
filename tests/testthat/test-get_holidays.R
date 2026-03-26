# nine nationwide German public holidays for 2023
nationwide_23 <- c(
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

test_that("returns nationwide holidays for a given year", {
  expect_equal(
    get_holidays(holidays_DE, years = 2023),
    nationwide_23
  )
})
