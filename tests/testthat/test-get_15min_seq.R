today <- Sys.Date()

test_that("get_15min_seq works", {
  expect_equal(length(get_15min_seq(today, today + 1)), 97L)
})
