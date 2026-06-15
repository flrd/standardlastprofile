all_gas_profiles <- c(
  "HEF",
  "HMF",
  "HKO",
  "GKO",
  "GHA",
  "GMK",
  "GBD",
  "GBH",
  "GWA",
  "GGA",
  "GBA",
  "GGB",
  "GPD",
  "GMF",
  "GHD"
)

# ---- slp_gas_coefficients ---------------------------------------------------

test_that("default returns all 15 profiles x 2 variants = 30 rows", {
  out <- slp_gas_coefficients()
  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 30L)
  expect_equal(sort(unique(out$profile_id)), sort(all_gas_profiles))
  expect_equal(sort(unique(out$variant)), c("33", "34"))
})

test_that("returns correct columns", {
  out <- slp_gas_coefficients("HEF", variant = "34")
  expect_named(
    out,
    c(
      "profile_id",
      "variant",
      "A",
      "B",
      "C",
      "D",
      "theta0",
      "mH",
      "bH",
      "mW",
      "bW"
    )
  )
})

test_that("single profile NULL variant returns 2 rows (both variants)", {
  out <- slp_gas_coefficients("HEF")
  expect_equal(nrow(out), 2L)
  expect_equal(out$profile_id, c("HEF", "HEF"))
  expect_equal(out$variant, c("34", "33"))
})

test_that("single profile single variant returns 1 row", {
  out <- slp_gas_coefficients("HEF", variant = "34")
  expect_equal(nrow(out), 1L)
  expect_equal(out$variant, "34")
})

test_that("multiple profiles, both variants returns 2 rows per profile", {
  out <- slp_gas_coefficients(c("HEF", "GKO", "GWA"))
  expect_equal(nrow(out), 6L)
  expect_equal(
    out$profile_id,
    rep(c("HEF", "GKO", "GWA"), each = 1L) |>
      (\(x) c(x, x))()
  )
})

test_that("variant = c('34', '33') is identical to variant = NULL", {
  expect_equal(
    slp_gas_coefficients(variant = c("34", "33")),
    slp_gas_coefficients()
  )
})

test_that("duplicate variants are silently deduplicated", {
  out_dedup <- slp_gas_coefficients("HEF", variant = c("33", "34", "33"))
  out_clean <- slp_gas_coefficients("HEF")
  expect_equal(nrow(out_dedup), 2L)
  expect_equal(out_dedup, out_clean[c(2L, 1L), ], ignore_attr = TRUE)
})

test_that("variant order in output follows order of variant arg", {
  out_34_first <- slp_gas_coefficients("HEF", variant = c("34", "33"))
  out_33_first <- slp_gas_coefficients("HEF", variant = c("33", "34"))
  expect_equal(out_34_first$variant, c("34", "33"))
  expect_equal(out_33_first$variant, c("33", "34"))
})

test_that("variant 33 and 34 coefficients differ for non-HKO profiles", {
  out <- slp_gas_coefficients("HEF")
  expect_false(
    out$A[out$variant == "34"] == out$A[out$variant == "33"]
  )
})

test_that("HKO linear coefficients are zero for both variants", {
  out <- slp_gas_coefficients("HKO")
  expect_true(all(out$mH == 0 & out$bH == 0 & out$mW == 0 & out$bW == 0))
})

test_that("theta0 is 40 for all profiles and both variants", {
  expect_true(all(slp_gas_coefficients()$theta0 == 40))
})

test_that("no row names", {
  out <- slp_gas_coefficients()
  expect_equal(rownames(out), as.character(seq_len(nrow(out))))
})

test_that("invalid profile_id raises an error", {
  expect_error(slp_gas_coefficients("H0"), "'profile_id' should be one of")
})

test_that("invalid variant raises an error", {
  expect_error(slp_gas_coefficients(variant = "35"), "'variant' must be")
})

test_that("numeric variant is accepted and equals character variant", {
  expect_equal(
    slp_gas_coefficients("HEF", variant = 34),
    slp_gas_coefficients("HEF", variant = "34")
  )
  expect_equal(
    slp_gas_coefficients("HEF", variant = 33),
    slp_gas_coefficients("HEF", variant = "33")
  )
  expect_equal(
    slp_gas_coefficients("HEF", variant = 34.00),
    slp_gas_coefficients("HEF", variant = "34")
  )
})

test_that("output is consistent with .gas_profile_params", {
  p <- slp_gas_coefficients("GBA", variant = "33")
  raw <- .gas_profile_params[["33"]][["GBA"]]
  expect_equal(p$A, raw$A)
  expect_equal(p$bW, raw$bW)
})

# ---- slp_gas_weekday_factors ------------------------------------------------

test_that("default returns all 15 profiles x 7 days = 105 rows", {
  out <- slp_gas_weekday_factors()
  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 105L)
})

test_that("returns correct columns", {
  out <- slp_gas_weekday_factors("HEF")
  expect_named(out, c("profile_id", "day", "f_wt"))
})

test_that("day column contains all seven abbreviated weekdays", {
  out <- slp_gas_weekday_factors("HEF")
  expect_equal(out$day, c("Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"))
})

test_that("single profile returns 7 rows", {
  out <- slp_gas_weekday_factors("GKO")
  expect_equal(nrow(out), 7L)
  expect_true(all(out$profile_id == "GKO"))
})

test_that("duplicate profile_id values are kept and order is preserved", {
  out <- slp_gas_weekday_factors(c("HEF", "GKO", "HEF"))
  expect_equal(nrow(out), 3L * 7L)
  expect_equal(rle(out$profile_id)$values, c("HEF", "GKO", "HEF"))
  # the two HEF blocks are identical and differ from the GKO block between them
  expect_identical(out$f_wt[1:7], out$f_wt[15:21])
  expect_false(identical(out$f_wt[1:7], out$f_wt[8:14]))
  # a duplicated block matches the single-profile result for that id
  single <- slp_gas_weekday_factors("GKO")
  expect_identical(out$f_wt[8:14], single$f_wt)
})

test_that("residential profiles have all f_wt equal to 1", {
  out <- slp_gas_weekday_factors(c("HEF", "HMF", "HKO"))
  expect_true(all(out$f_wt == 1))
})

test_that("f_wt values are positive", {
  out <- slp_gas_weekday_factors()
  expect_true(all(out$f_wt > 0))
})

test_that("no row names", {
  out <- slp_gas_weekday_factors()
  expect_equal(rownames(out), as.character(seq_len(nrow(out))))
})

test_that("invalid profile_id raises an error", {
  expect_error(slp_gas_weekday_factors("H0"), "'profile_id' should be one of")
})

test_that("output is consistent with .gas_weekday_factors", {
  out <- slp_gas_weekday_factors("GWA")
  raw <- .gas_weekday_factors[["GWA"]]
  expect_equal(out$f_wt[out$day == "Mo"], unname(raw["Mo"]))
  expect_equal(out$f_wt[out$day == "Sa"], unname(raw["Sa"]))
})
