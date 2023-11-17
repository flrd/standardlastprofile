test_that("is_date works", {
  expect_equal(is_date(Sys.Date()), TRUE)
})

test_that("is_date works", {
  expect_equal(is_date("Sys.Date()"), FALSE)
})
