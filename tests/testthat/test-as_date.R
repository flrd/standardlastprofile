today <- Sys.Date()

test_that("as_date works", {
  expect_equal(today, today |> as.character() |> as_date())
})

test_that("as_date returns NA in case of error", {
  expect_equal("today, today |> as.character()" |> as_date(), NA_character_)
})

test_that("as_date returns NA in case of error", {
  expect_equal("2022-13-01" |> as_date(), NA_character_)
})
