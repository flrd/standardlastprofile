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


# Regression test for https://github.com/flrd/standardlastprofile/issues/3
# When a date range contains a Dec 31 that is a Sunday, the christmastide rule
# must still promote *other* Dec 31s (that are not a Sunday) to Saturday.
# The old code used all() which failed if any Dec 31 in the range was a Sunday.
test_that("christmastide rule is applied per-date, not across the whole range", {
  dates <- as.Date(c("2023-12-31", "2024-12-31")) # Sunday, then Tuesday
  expect_equal(get_weekday(dates), c("sunday", "saturday"))
})

test_that("december 24, and 31st are set to be a saturday, if they are not a sunday", {
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
