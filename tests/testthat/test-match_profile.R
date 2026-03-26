test_that("match_profile returns valid IDs unchanged", {
  expect_equal(match_profile(c("G1", "G2")), c("G1", "G2"))
})

test_that("match_profile preserves duplicates", {
  expect_equal(match_profile(c("G1", "G1", "G2")), c("G1", "G1", "G2"))
})

test_that("match_profile upcases lowercase input", {
  expect_equal(match_profile(c("g1", "g2")), c("G1", "G2"))
})

test_that("match_profile errors on any invalid ID", {
  expect_error(
    match_profile(c("ABC", "G1", "G2")),
    "'profile_id' should be one of"
  )
})

test_that("match_profile errors on single invalid ID", {
  expect_error(match_profile("ABC"), "'profile_id' should be one of")
})

test_that("match_profile errors on NULL", {
  expect_error(match_profile(NULL), "Please provide at least one value")
})

test_that("match_profile errors on character(0)", {
  expect_error(match_profile(character(0)), "Please provide at least one value")
})
