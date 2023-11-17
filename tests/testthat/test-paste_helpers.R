test_that("paste_dash works", {
  expect_equal(paste_dash(2, 2), "2-2")
})

test_that("paste_snake works", {
  expect_equal(paste_snake(2, 2), "2_2")
})
