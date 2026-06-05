#' Compute Dimensionless Daily Heating Demand (SigLinDe)
#'
#' Computes the dimensionless daily heating demand \eqn{h(\vartheta)} for a
#' given outdoor temperature using the SigLinDe
#' (Sigmoid + Linear + Deutschland) method defined in the BDEW/VKU/GEODE
#' Leitfaden.
#'
#' The function value is the sum of a sigmoid part and a linear part:
#'
#' \deqn{h(\vartheta) = \frac{A}{1 + \left(\frac{B}{\vartheta -
#'   \vartheta_0}\right)^C} + D + \max(m_H \vartheta + b_H,\;
#'   m_W \vartheta + b_W)}
#'
#' The sigmoid captures the non-linear relationship between outdoor temperature
#' and heating demand. The linear envelope of two lines represents
#' space-heating demand (*Heizgas-Gerade*, slope `mH`) and hot-water demand
#' (*Warmwasser-Gerade*, slope `mW`).
#'
#' For residential profiles (e.g. `HEF`, `HMF`) both parts contribute.
#' For the `HKO` (TUM) profile the linear coefficients are all zero, so only
#' the sigmoid part remains.
#'
#' @param theta Numeric vector of daily mean outdoor temperatures in °C
#'   (*Allokationstemperatur*).
#' @param A,B,C,D Numeric scalars — sigmoid coefficients.
#' @param theta0 Numeric scalar — pole temperature (40 °C for all published
#'   profiles). The function is undefined at \eqn{\vartheta = \vartheta_0} and
#'   physically meaningless above it.
#' @param mH,bH Numeric scalars — slope and intercept of the heating linear
#'   component (*Heizgas-Gerade*).
#' @param mW,bW Numeric scalars — slope and intercept of the hot-water linear
#'   component (*Warmwasser-Gerade*).
#'
#' @return A numeric vector the same length as `theta` giving the
#'   dimensionless profile value \eqn{h(\vartheta)} for each temperature.
#'
#' @details
#' This is the low-level building block used internally by [slp_gas()]. It is
#' exported so that users with custom or region-specific coefficients (e.g.
#' state-level parameters such as `BW_HEF03` for Baden-Württemberg) can
#' compute \eqn{h(\vartheta)} directly and build their own profiles.
#'
#' Published coefficients for all 15 standard profiles are listed in the
#' \href{https://flrd.github.io/standardlastprofile/articles/slp-gas-parameters.html}{SigLinDe parameters}
#' article.
#'
#' @references
#' BDEW/VKU/GEODE (2025). *Abwicklung von Standardlastprofilen Gas*,
#' Kooperationsvereinbarung Gas, Anlage XIV.2, as of 2025-10-28, Anhang 6,
#' pp. 145–166.
#' \url{https://www.bdew.de/media/documents/251028_LF_SLP_Gas_KoV_XIV.2.pdf}
#'
#' @seealso [slp_gas()];
#'   \href{https://flrd.github.io/standardlastprofile/articles/slp-gas-parameters.html}{SigLinDe parameters}
#'   article
#' @export
#' @examples
#' # h value at 0 °C for HEF (single-family home), variant 34
#' slp_gas_siglinde(
#'   theta = 0,
#'   A = 1.3819663, B = -37.4124155, C = 6.1723179, D = 0.0396284,
#'   theta0 = 40,
#'   mH = -0.0672159, bH = 1.1167138,
#'   mW = -0.0019982, bW = 0.1355070
#' )
#'
#' # h values across a temperature range
#' temps <- seq(-15, 30, by = 5)
#' slp_gas_siglinde(
#'   theta = temps,
#'   A = 1.3819663, B = -37.4124155, C = 6.1723179, D = 0.0396284,
#'   theta0 = 40,
#'   mH = -0.0672159, bH = 1.1167138,
#'   mW = -0.0019982, bW = 0.1355070
#' )
slp_gas_siglinde <- \(theta, A, B, C, D, theta0, mH, bH, mW, bW) {
  # theta0 = 40 for all published profiles.
  # At theta == theta0 the denominator is zero (undefined).
  # At theta >  theta0 the base B/(theta-theta0) is negative; raising a
  # negative number to a non-integer C produces NaN in R.
  # Both cases are physically unrealistic (no German outdoor temperature
  # reaches 40 °C) but we guard defensively.
  if (any(theta >= theta0)) {
    stop(
      "'theta' must be below the pole temperature (",
      theta0,
      " \u00b0C). Values at or above this temperature are not supported."
    )
  }
  sigmoid_part <- A / (1 + (B / (theta - theta0))^C) + D
  linear_part <- pmax(mH * theta + bH, mW * theta + bW)
  sigmoid_part + linear_part
}
