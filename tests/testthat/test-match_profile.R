test_that("match_profile works", {
  expect_equal(match_profile(c("ABC", "G1", "G1", "G2")), c("G1", "G2"))
})

test_that("match_profile expects a BDEW profile", {
  expect_error(match_profile("ABC"), "'profile_id' should be one of 'H0', 'G0', 'G1', 'G2', 'G3', 'G4', 'G5', 'G6', 'L0', 'L1', 'L2'.")
})
