#' Retrieve SigLinDe Coefficients for Gas Standard Load Profiles
#'
#' Returns the SigLinDe profile function coefficients for one or more gas
#' standard load profiles as a data frame. These are the values used
#' internally by [slp_gas()] and [slp_gas_siglinde()].
#'
#' @param profile_id character vector of gas profile identifiers. One or more
#'   of `"HEF"`, `"HMF"`, `"HKO"`, `"GKO"`, `"GHA"`, `"GMK"`, `"GBD"`,
#'   `"GBH"`, `"GWA"`, `"GGA"`, `"GBA"`, `"GGB"`, `"GPD"`, `"GMF"`,
#'   `"GHD"`. Pass `NULL` (the default) to retrieve all 15 profiles.
#' @param variant character vector of SigLinDe variants to include. One or
#'   both of `"34"` (57 % linear component) and `"33"` (45 % linear
#'   component). Pass `NULL` (the default) to retrieve both variants.
#'   Duplicate values are silently ignored.
#'
#' @return A data frame with one row per profile–variant combination and
#'   11 variables:
#' \describe{
#'   \item{profile_id}{character, gas profile identifier}
#'   \item{variant}{character, SigLinDe variant (`"34"` or `"33"`)}
#'   \item{A, B, C, D}{numeric, sigmoid coefficients}
#'   \item{theta0}{numeric, pole temperature (40 °C for all published profiles)}
#'   \item{mH, bH}{numeric, slope and intercept of the space-heating line
#'     (*Heizgas-Gerade*)}
#'   \item{mW, bW}{numeric, slope and intercept of the hot-water line
#'     (*Warmwasser-Gerade*)}
#' }
#'
#' @details
#' The `HKO` profile (Kochgasprofil) is a pure sigmoid with no linear
#' component; its `mH`, `bH`, `mW`, and `bW` are all zero for both variants.
#'
#' The returned coefficients can be passed directly to [slp_gas_siglinde()]
#' for custom calculations. When selecting a single profile and variant the
#' result is a one-row data frame, so use `[[ ]]` or `$` to extract scalars:
#'
#' ```r
#' p <- slp_gas_coefficients("HEF", variant = "34")
#' slp_gas_siglinde(0, p$A, p$B, p$C, p$D, p$theta0, p$mH, p$bH, p$mW, p$bW)
#' ```
#'
#' @source BDEW/VKU/GEODE (2025). *Leitfaden Abwicklung von Standardlastprofilen
#'   Gas*, Kooperationsvereinbarung Gas, Annex XIV.2, as of 2025-10-28,
#'   Appendix 6.
#'   \url{https://www.bdew.de/media/documents/251028_LF_SLP_Gas_KoV_XIV.2.pdf}
#'
#' @seealso [slp_gas_siglinde()], [slp_gas()], [slp_gas_weekday_factors()];
#'   all values are listed in tabular form in the
#'   \href{https://flrd.github.io/standardlastprofile/articles/slp-gas-parameters.html}{SigLinDe parameters}
#'   article.
#' @export
#' @examples
#' # Single profile, both variants
#' slp_gas_coefficients("HEF")
#'
#' # Single profile, single variant
#' slp_gas_coefficients("HEF", variant = "34")
#'
#' # Both variants explicitly — same as NULL
#' slp_gas_coefficients(c("HEF", "GKO"), variant = c("34", "33"))
slp_gas_coefficients <- \(
  profile_id = NULL,
  variant = NULL
) {
  valid_variants <- c("34", "33")

  if (is.null(variant)) {
    variant <- valid_variants
  } else {
    if (!is.character(variant) || !all(variant %in% valid_variants)) {
      stop("'variant' must be \"34\", \"33\", or a combination of both.")
    }
    variant <- unique(variant)
  }

  if (is.null(profile_id)) {
    profile_id <- names(.gas_profile_params[["34"]])
  } else {
    profile_id <- .match_profile_gas(profile_id)
  }

  rows <- unlist(
    lapply(variant, \(v) {
      lapply(profile_id, \(pid) {
        p <- .gas_profile_params[[v]][[pid]]
        data.frame(
          profile_id = pid,
          variant = v,
          A = p$A,
          B = p$B,
          C = p$C,
          D = p$D,
          theta0 = p$theta0,
          mH = p$mH,
          bH = p$bH,
          mW = p$mW,
          bW = p$bW
        )
      })
    }),
    recursive = FALSE
  )
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result
}


#' Retrieve Weekday Factors for Gas Standard Load Profiles
#'
#' Returns the weekday scaling factors (\eqn{F_{WT}}) for one or more gas standard
#' load profiles as a data frame. These are the values used internally by
#' [slp_gas()].
#'
#' @param profile_id character vector of gas profile identifiers. Same values
#'   as [slp_gas()]. Pass `NULL` (the default) to retrieve all 15 profiles.
#'
#' @return A data frame with one row per profile–day combination and 3
#'   variables:
#' \describe{
#'   \item{profile_id}{character, gas profile identifier}
#'   \item{day}{character, abbreviated weekday: `"Mo"`, `"Tu"`, `"We"`,
#'     `"Th"`, `"Fr"`, `"Sa"`, `"Su"`}
#'   \item{f_wt}{numeric, weekday scaling factor}
#' }
#'
#' @details
#' For the residential profiles `HEF`, `HMF`, and `HKO` all weekday factors
#' are 1: gas consumption in households is assumed not to vary by day of the
#' week. Commercial profiles show sector-specific patterns — for
#' example, `GWA` (laundries) has high Monday–Wednesday factors (busy wash
#' days) and very low weekend factors.
#'
#' Public holidays are treated as Sunday (`"Su"`); 24 and 31 December are
#' treated as Saturday (`"Sa"`) unless they fall on a Sunday. See [slp_gas()]
#' for details.
#'
#' @source BDEW/VKU/GEODE (2025). *Leitfaden Abwicklung von Standardlastprofilen
#'   Gas*, Kooperationsvereinbarung Gas, Annex XIV.2, as of 2025-10-28,
#'   Appendix 6.
#'   \url{https://www.bdew.de/media/documents/251028_LF_SLP_Gas_KoV_XIV.2.pdf}
#'
#' @seealso [slp_gas()], [slp_gas_coefficients()];
#'   all values are listed in tabular form in the
#'   \href{https://flrd.github.io/standardlastprofile/articles/slp-gas-parameters.html}{SigLinDe parameters}
#'   article.
#' @export
#' @examples
#' slp_gas_weekday_factors(c("HEF", "GWA"))
slp_gas_weekday_factors <- \(profile_id = NULL) {
  if (is.null(profile_id)) {
    profile_id <- names(.gas_weekday_factors)
  } else {
    profile_id <- .match_profile_gas(profile_id)
  }

  days <- c("Mo", "Tu", "We", "Th", "Fr", "Sa", "Su")

  rows <- lapply(profile_id, \(pid) {
    fwt <- .gas_weekday_factors[[pid]]
    data.frame(
      profile_id = pid,
      day = days,
      f_wt = unname(fwt[days])
    )
  })
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result
}
