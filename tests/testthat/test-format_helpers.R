tmp <- as_date("2023-12-24")

test_that("format_u works", {
  expect_equal(format_u(tmp), "7")
})

test_that("format_md works", {
  expect_equal(format_md(tmp), "12-24")
})

test_that("format_Y works", {
  expect_equal(format_Y(tmp), "2023")
})

test_that("format_Y works", {
  expect_equal(format_j(tmp), "358")
})
