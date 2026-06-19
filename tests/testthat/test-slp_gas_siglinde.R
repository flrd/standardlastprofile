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

# ---- coefficient validation (exported function: custom coefficients) --------

test_that("a non-finite coefficient raises a clear error naming the coefficient", {
  # A = NA previously returned NA silently
  expect_error(
    slp_gas_siglinde(
      0,
      A = NA_real_,
      B = -37.4,
      C = 6.17,
      D = 0.04,
      theta0 = 40,
      mH = -0.067,
      bH = 1.12,
      mW = -0.002,
      bW = 0.14
    ),
    "coefficient.*A"
  )
  # theta0 = NA previously gave "missing value where TRUE/FALSE needed"
  expect_error(
    slp_gas_siglinde(
      0,
      A = 1.38,
      B = -37.4,
      C = 6.17,
      D = 0.04,
      theta0 = NA_real_,
      mH = -0.067,
      bH = 1.12,
      mW = -0.002,
      bW = 0.14
    ),
    "coefficient.*theta0"
  )
  # B = Inf
  expect_error(
    slp_gas_siglinde(
      0,
      A = 1.38,
      B = Inf,
      C = 6.17,
      D = 0.04,
      theta0 = 40,
      mH = -0.067,
      bH = 1.12,
      mW = -0.002,
      bW = 0.14
    ),
    "coefficient.*B"
  )
})

test_that("a non-scalar coefficient is rejected (no silent recycling)", {
  # C as a length-2 vector previously recycled silently into the output
  expect_error(
    slp_gas_siglinde(
      c(0, 5),
      A = 1.38,
      B = -37.4,
      C = c(6.17, 2),
      D = 0.04,
      theta0 = 40,
      mH = -0.067,
      bH = 1.12,
      mW = -0.002,
      bW = 0.14
    ),
    "coefficient.*C"
  )
})

test_that("a non-numeric coefficient is rejected and all offenders are listed", {
  expect_error(
    slp_gas_siglinde(
      0,
      A = NA_real_,
      B = -37.4,
      C = 6.17,
      D = 0.04,
      theta0 = 40,
      mH = -0.067,
      bH = 1.12,
      mW = "x",
      bW = 0.14
    ),
    "coefficient.*A, mW"
  )
})

test_that("a numeric matrix theta is accepted and computed element-wise", {
  m <- matrix(c(0, 5, 8, -3), nrow = 2)
  out <- h(m)
  expect_true(is.matrix(out))
  expect_equal(dim(out), c(2L, 2L))
  expect_equal(as.vector(out), h(as.vector(m)))
})

# ---- oracle: BDEW/VKU/GEODE Leitfaden Anlage 1 ------------------------------
# External oracle from the source of truth: "Abwicklung von Standardlastprofilen
# Gas", Stand 27.03.2026, Anlage 1 "Ermittlung des Kundenwertes", Seite 122-126
# (Tabelle 18-21). These are pure-sigmoid profiles (linear part zero), so the
# call sets mH = bH = mW = bW = 0. The published temperatures are rounded to
# 2 dp and the h-values to ~5 dp, which sets the achievable tolerance (the raw
# deviation against our function is < 1e-5).

# Temperatures (geometrically-weighted daily temperature) shared by both tables.
leitfaden_theta <- c(
  12.16,
  11.67,
  12.00,
  14.44,
  15.43,
  15.63,
  10.99,
  13.11,
  13.23,
  13.78,
  12.74
)

test_that("siglinde reproduces the Leitfaden Heizgas h-values (Tabelle 19)", {
  # legacy pre-SigLinDe EFHo Klasse-3 profile from the worked Heizgas example
  published <- c(
    0.57689,
    0.61938,
    0.59054,
    0.40687,
    0.34727,
    0.33624,
    0.68167,
    0.50046,
    0.49138,
    0.45136,
    0.52929
  )
  ours <- slp_gas_siglinde(
    leitfaden_theta,
    A = 3.0553842,
    B = -37.1836374,
    C = 5.6810825,
    D = 0.0821966,
    theta0 = 40,
    mH = 0,
    bH = 0,
    mW = 0,
    bW = 0
  )
  expect_equal(ours, published, tolerance = 1e-4)
})

test_that("siglinde reproduces the Leitfaden Kochgas (HKO) h-values (Tabelle 21)", {
  # "DE HKO" — the same profile shipped in this package (see next test)
  published <- c(
    0.99438,
    1.00385,
    0.99755,
    0.94237,
    0.91636,
    0.91093,
    1.01596,
    0.974256,
    0.971549,
    0.958696,
    0.982373534
  )
  ours <- slp_gas_siglinde(
    leitfaden_theta,
    A = 0.4040932,
    B = -24.4392968,
    C = 6.5718175,
    D = 0.71077105,
    theta0 = 40,
    mH = 0,
    bH = 0,
    mW = 0,
    bW = 0
  )
  expect_equal(ours, published, tolerance = 1e-4)
})

test_that("shipped HKO coefficients match the Leitfaden 'DE HKO' parameters", {
  # ties the Tabelle 21 oracle above to the coefficients we actually ship
  hko <- slp_gas_coefficients("HKO", variant = "34")
  expect_equal(hko$A, 0.4040932, tolerance = 1e-7)
  expect_equal(hko$B, -24.4392968, tolerance = 1e-7)
  expect_equal(hko$C, 6.5718175, tolerance = 1e-7)
  expect_equal(hko$D, 0.71077105, tolerance = 1e-7)
  expect_equal(hko$theta0, 40)
})
