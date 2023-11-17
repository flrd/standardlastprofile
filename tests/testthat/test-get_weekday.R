x <- seq.Date(as.Date("2023-12-22"), as.Date("2024-01-03"), by = "day")

test_that("get_weekday() works", {
  expect_equal(get_weekday(x),
               c("workday",
                 "saturday",
                 "sunday",
                 "sunday",
                 "sunday",
                 "workday",
                 "workday",
                 "workday",
                 "saturday",
                 "sunday",
                 "sunday",
                 "workday",
                 "workday"
                 )
               )
})

jan_first <- paste0(2020:2025, "-01-01") |> as.Date()
test_that("get_weekday() sets Jan 1st to 'sunday'", {
  expect_equal(get_weekday(jan_first), rep("sunday", length(jan_first)))
})
