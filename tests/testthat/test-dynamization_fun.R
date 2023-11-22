test_that("dynamization_fun works", {
  expect_equal(
    dynamization_fun(c(1, 100, 200, 300, 366)),
    c(1.24203012, 1.0288, 0.7848, 1.0168, 1.25968523)
  )
})
