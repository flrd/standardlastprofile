# nine nationwide German public holidays for 2023
nationwide_23 <- as.Date(c(
  "2023-01-01",
  "2023-04-07",
  "2023-04-10",
  "2023-05-01",
  "2023-05-18",
  "2023-05-29",
  "2023-10-03",
  "2023-12-25",
  "2023-12-26"
))

test_that("computes nationwide holidays for a given year", {
  expect_equal(.holidays_de(2023L), nationwide_23)
})

test_that("Easter cluster 2099 matches the published Anonymous Gregorian result", {
  # Verifies the algorithm at the upper end of the previously-tabled range.
  # Source: https://www.bdew.de (and any standard German Feiertagskalender)
  e <- .easter_sunday(2099L)
  expect_equal(e, as.Date("2099-04-12")) # Ostersonntag
  expect_equal(e - 2L, as.Date("2099-04-10")) # Karfreitag
  expect_equal(e + 1L, as.Date("2099-04-13")) # Ostermontag
})

test_that("years before 1990 are silently dropped", {
  expect_equal(.holidays_de(1980L), as.Date(character(0L)))
  expect_equal(.holidays_de(c(1985L, 1990L)), .holidays_de(1990L))
})

test_that("vector of years returns the union of all holidays", {
  out <- .holidays_de(c(2023L, 2024L))
  expect_length(out, 18L)
  expect_true(all(format(out, "%Y") %in% c("2023", "2024")))
})

test_that("2008: Himmelfahrt coincides with Tag der Arbeit without breaking logic", {
  # Easter 2008 is March 23; Easter + 39 = May 1 = Tag der Arbeit.
  # holidays_de() returns a duplicate May 1 in this case. The duplicate is
  # harmless for %in% lookups but the total length is 9 (not deduplicated).
  h <- .holidays_de(2008L)
  expect_length(h, 9L)
  expect_equal(sum(h == as.Date("2008-05-01")), 2L)
  # get_weekday() must still treat May 1 as Sunday despite the duplicate
  expect_equal(.get_weekday(as.Date("2008-05-01")), "sunday")
})
