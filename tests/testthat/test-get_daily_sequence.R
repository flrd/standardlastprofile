test_that("get_daily_sequence() works", {
  expect_equal(get_daily_sequence("2023-11-08", "2023-11-11"),
               seq.Date(as.Date("2023-11-08"), as.Date("2023-11-11"), by = "day"))
})

test_that("get_daily_sequence() errors if start_date > end_date", {
  expect_error(get_daily_sequence("2023-11-11", "2023-11-10"))
})

test_that("get_daily_sequence() expects objects of type 'Date'", {
  expect_error(get_daily_sequence("abc", "2023-11-11"))
})

test_that("'start_date and 'end_date' must be of length one.", {
  expect_error(get_daily_sequence(Sys.Date(), Sys.Date() + 1:2))
})
