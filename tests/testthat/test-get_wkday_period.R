test_that("get_wkday_period works", {
  expect_equal("2023-11-17" |> as_date() |> get_wkday_period(), "workday_winter")
})

test_that("get_wkday_period expects Date object", {
  expect_error(get_wkday_period("2023-11-17"), "'x' must be an object of class 'Date'")
})
