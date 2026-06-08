# A valid SigLinDe parameter set (HMF / GMF, variant 34) for the tests
p <- list(
  A = 1.0443538,
  B = -35.0333754,
  C = 6.2240634,
  D = 0.0502917,
  theta0 = 40,
  mH = -0.053583,
  bH = 0.9995901,
  mW = -0.0021758,
  bW = 0.1633299
)
h <- function(theta) {
  slp_gas_siglinde(theta, p$A, p$B, p$C, p$D, p$theta0, p$mH, p$bH, p$mW, p$bW)
}

test_that("returns a numeric vector the same length as theta", {
  out <- h(c(-10, 0, 8, 20))
  expect_type(out, "double")
  expect_length(out, 4L)
  expect_true(all(out > 0))
})

test_that("h equals 1 at the 8 degC reference for a SigLinDe profile", {
  expect_equal(h(8), 1, tolerance = 1e-6)
})

# ---- theta validation (exported function: validate its own input) -----------

test_that("theta containing NA raises a clear error (not a cryptic one)", {
  expect_error(h(c(0, NA)), "finite")
})

test_that("theta containing NaN raises a clear error", {
  expect_error(h(c(0, NaN)), "finite")
})

test_that("theta containing Inf / -Inf raises a clear error", {
  expect_error(h(Inf), "finite")
  expect_error(h(c(0, -Inf)), "finite")
})

test_that("non-numeric theta raises a clear error (not the pole message)", {
  expect_error(h("a"), "must be a numeric vector")
  expect_error(h(list(0, 5)), "must be a numeric vector")
})

test_that("theta at or above the pole temperature is rejected", {
  expect_error(h(40), "pole temperature")
  expect_error(h(45), "pole temperature")
})

test_that("a numeric matrix theta is accepted and computed element-wise", {
  m <- matrix(c(0, 5, 8, -3), nrow = 2)
  out <- h(m)
  expect_true(is.matrix(out))
  expect_equal(dim(out), c(2L, 2L))
  expect_equal(as.vector(out), h(as.vector(m)))
})
