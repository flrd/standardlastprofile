test_that("standardise_state_names() works", {
  expect_equal(standardise_state_names("BE"), "DE-BE")
})

test_that("standardise_state_names() expects state code", {
  expect_error(standardise_state_names("ABC"))
})
