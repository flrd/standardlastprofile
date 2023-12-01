x <-
  seq.Date(as.Date("2023-12-22"), as.Date("2024-01-03"), by = "day")

test_that("get_weekday() works", {
  expect_equal(
    get_weekday(x),
    c(
      "workday",
      "saturday",
      "sunday",
      "sunday",
      "sunday",
      "workday",
      "workday",
      "workday",
      "saturday",
      "sunday",
      "sunday",
      "workday",
      "workday"
    )
  )
})

jan_first <- paste0(2020:2025, "-01-01") |> as.Date()
test_that("get_weekday() sets Jan 1st to 'sunday'", {
  expect_equal(get_weekday(jan_first), rep("sunday", length(jan_first)))
})


test_that("december 24, and 31st are set to be a saturday, if they are not a sunday",
          {
            expect_equal(
              get_weekday(get_daily_sequence("2021-12-21", "2022-01-01")),
              c(
                "workday",
                "workday",
                "workday",
                "saturday",
                "sunday",
                "sunday",
                "workday",
                "workday",
                "workday",
                "workday",
                "saturday",
                "sunday"
              )
            )
          })
