test_that("get_daily_sequence() works", {
  expect_equal(get_daily_sequence("2023-11-08", "2023-11-11"),
               seq.Date(as.Date("2023-11-08"), as.Date("2023-11-11"), by = "day"))
})

test_that("get_daily_sequence() errors if start_date > end_date", {
  expect_error(get_daily_sequence("2023-11-11", "2023-11-10"))
})
