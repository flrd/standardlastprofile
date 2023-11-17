test_that("get_period knows when it's winter", {
  expect_equal(get_period(as_date(c("2022-11-09", "2022-11-11"))), c("winter", "winter"))
})

test_that("get_period knows when it's transition", {
  expect_equal(get_period(as_date("2022-04-01")), "transition")
})

test_that("get_period knows when it's summer", {
  expect_equal(get_period(as_date("2022-05-15")), "summer")
})

test_that("get_period expects Date object", {
  expect_error(get_period("2023-11-17"), "'x' must be an object of class 'Date'")
})
