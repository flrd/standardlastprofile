#' Compute the Kundenwert for a Gas Standard Load Profile
#'
#' Compute the customer value (Kundenwert, KW) that scales a gas standard load
#' profile to a specific annual consumption. The result can be passed directly
#' to [slp_gas()] via its `kundenwert` argument, enabling a two-step
#' workflow: derive KW from a representative full-year reference temperature
#' series, then generate profiles for any shorter period using that fixed KW.
#'
#' @param profile_id gas load profile identifier, required. Same values as
#'   [slp_gas()]. Multiple values are supported; the result is a
#'   named numeric vector with one element per profile.
#' @param dates a Date vector or character vector in ISO 8601 format
#'   (`"YYYY-MM-DD"`), representing a **full reference year** of daily dates.
#'   For a meaningful Kundenwert the series should ideally cover 365 (or 366)
#'   days. Must have the same length as `temperatures`.
#' @param temperatures a numeric vector of daily temperatures in degrees
#'   Celsius. Must have the same length as `dates`.
#' @param annual_consumption numeric scalar, annual gas consumption in kWh.
#'   Defaults to `1000`.
#' @param variant SigLinDe variant, either `"34"` (default) or `"33"`. Must
#'   match the `variant` passed to [slp_gas()] when applying the
#'   resulting Kundenwert.
#' @param holidays controls public holiday treatment. Same semantics as in
#'   [slp_gas()]. The reference year used here should apply the same
#'   holiday calendar as the generation step.
#'
#' @return A named numeric vector of length `length(profile_id)`. Each element
#'   is the Kundenwert in kWh/day for the corresponding profile. Names match
#'   the input `profile_id` values.
#'
#' @details
#' The Kundenwert is derived from the annual consumption and the year's
#' temperature profile:
#'
#' \deqn{KW = \frac{Q_a}{\sum_D h(\vartheta_D) \cdot F_{WT,D}}}
#'
#' where \eqn{Q_a} is `annual_consumption` (the annual consumption total; German:
#' *Jahresverbrauchsprognose*, JVP) and the sum \eqn{\sum_D h(\vartheta_D) \cdot
#' F_{WT,D}} runs over all days in the temperature and weekday factor series.
#' For the result to be meaningful the denominator must reflect a full seasonal
#' cycle (ideally a calendar year).
#'
#' ## Reference temperature series
#'
#' For a robust Kundenwert the temperature series should represent a **full
#' reference year**, ideally a multi-year climatological mean rather than a
#' single year, so that no individual-year anomaly distorts the scaling factor;
#' with fewer than 365 days a message is shown.
#'
#' Daily mean temperatures can be downloaded from the DWD (Deutscher
#' Wetterdienst) open-data archive, e.g. via the
#' \href{https://brry.github.io/rdwd/}{rdwd} package. The
#' \href{https://flrd.github.io/standardlastprofile/articles/slp-gas.html}{gas SLP}
#' article on the package website walks through fetching DWD data, deriving the
#' Kundenwert, and generating profiles.
#'
#' ## Recommended workflow
#'
#' [slp_gas()] requires a `kundenwert`. If you do not already know it, compute
#' it first with `slp_gas_kundenwert()` from a full reference year and the
#' customer's annual consumption, then pass the result into [slp_gas()] to
#' generate the profile for whatever period you need:
#'
#' ```r
#' # Step 1 — derive KW from a full-year reference temperature series
#' kw <- slp_gas_kundenwert("HEF", dates_year, temps_year, annual_consumption = 15000)
#'
#' # Step 2 — generate a profile for any shorter period
#' slp_gas("HEF", dates_jan_mar, temps_jan_mar, kundenwert = kw)
#' ```
#'
#' @seealso [slp_gas()]
#' @export
#' @examples
#' # Derive KW from a full-year reference temperature series
#' dates_ref <- seq.Date(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "day")
#' doy       <- as.integer(format(dates_ref, "%j"))
#'
#' # fake temperature data for demonstration here only
#' temps_ref <- 10 - 11 * cos(2 * pi * (doy - 15) / 365)
#' slp_gas_kundenwert("HEF", dates = dates_ref, temperatures = temps_ref,
#'                    annual_consumption = 15000)
#'
#' # Multiple profiles at once
#' slp_gas_kundenwert(c("HEF", "GKO", "GWA"), dates_ref, temps_ref,
#'                    annual_consumption = 15000)
slp_gas_kundenwert <- \(
  profile_id,
  dates = NULL,
  temperatures = NULL,
  annual_consumption = 1000,
  variant = c("34", "33"),
  holidays = NULL
) {
  # ---- validate variant ---------------------------------------------------
  variant <- match.arg(as.character(variant), c("34", "33"))

  # ---- validate profile_id ------------------------------------------------
  profile_id <- .match_profile_gas(profile_id)

  # ---- resolve dates / temperatures ----------------------------------------
  has_dates <- !is.null(dates)
  has_temps <- !is.null(temperatures)

  if (!has_dates && !has_temps) {
    stop("Please supply 'dates' and 'temperatures'.")
  }

  if (has_dates != has_temps) {
    stop("'dates' and 'temperatures' must both be supplied or both be NULL.")
  }

  # ---- validate dates -----------------------------------------------------
  if (is.character(dates)) {
    parsed <- as.Date(dates, format = "%Y-%m-%d")
    # catches both wrong format and calendar-invalid dates (e.g. 2026-02-30),
    # which as.Date() returns as NA with an explicit format
    if (!all(grepl("^\\d{4}-\\d{2}-\\d{2}$", dates)) || anyNA(parsed)) {
      stop(
        "'dates' must contain valid dates in ISO 8601 format (\"YYYY-MM-DD\")."
      )
    }
    dates <- parsed
  }
  if (!.is_date(dates)) {
    stop(
      "'dates' must be a Date vector or character vector in ISO 8601 format."
    )
  }
  if (length(dates) == 0L) {
    stop("'dates' must contain at least one element.")
  }
  if (anyNA(dates)) {
    stop("'dates' must not contain NA values.")
  }

  # ---- validate temperatures ----------------------------------------------
  if (!is.numeric(temperatures)) {
    stop("'temperatures' must be a numeric vector.")
  }
  if (anyNA(temperatures)) {
    stop("'temperatures' must not contain NA values.")
  }
  if (!all(is.finite(temperatures))) {
    stop("'temperatures' must contain only finite values (no Inf or -Inf).")
  }

  # ---- validate matching lengths ------------------------------------------
  if (length(dates) != length(temperatures)) {
    stop("'dates' and 'temperatures' must have the same length.")
  }

  # ---- validate annual_consumption ----------------------------------------
  if (
    !is.numeric(annual_consumption) ||
      length(annual_consumption) != 1L ||
      !is.finite(annual_consumption) ||
      annual_consumption <= 0
  ) {
    stop("'annual_consumption' must be a single finite positive numeric value.")
  }

  # ---- validate holidays --------------------------------------------------
  if (is.logical(holidays) && length(holidays) == 1L && is.na(holidays)) {
    holidays <- as.Date(character(0L))
  }

  if (!is.null(holidays)) {
    if (!is.character(holidays) && !.is_date(holidays)) {
      stop("'holidays' must be NA, or a character or Date vector.")
    }
    if (is.character(holidays) && anyNA(holidays)) {
      stop(
        "Use `holidays = NA` to disable all holiday adjustments; ",
        "'holidays' must not contain NA values."
      )
    }
    if (
      is.character(holidays) &&
        !all(grepl("^\\d{4}-\\d{2}-\\d{2}$", holidays))
    ) {
      stop(
        "'holidays' must contain valid dates in ISO 8601 format (\"YYYY-MM-DD\")."
      )
    }
    holidays <- .as_date(holidays)
    if (anyNA(holidays)) {
      stop(
        "'holidays' must contain valid dates in ISO 8601 format (\"YYYY-MM-DD\")."
      )
    }
  }

  # ---- message when series is short ----------------------------------------
  if (length(dates) < 365L) {
    message(
      "'dates' covers only ",
      length(dates),
      " day(s). ",
      "The Kundenwert is only meaningful when derived from a full reference ",
      "year (365 or 366 days). With fewer days the seasonal cycle is ",
      "incomplete and the resulting Kundenwert will not correctly scale ",
      "the annual consumption across all seasons."
    )
  }

  # ---- compute weekday keys -----------------------------------------------
  wt_keys <- .get_gas_weekday_key(dates, holidays = holidays)

  # ---- compute KW for each profile ----------------------------------------
  out <- vapply(
    profile_id,
    function(pid) {
      params <- .gas_profile_params[[variant]][[pid]]
      fwt <- .gas_weekday_factors[[pid]]
      h_vals <- slp_gas_siglinde(
        theta = temperatures,
        A = params$A,
        B = params$B,
        C = params$C,
        D = params$D,
        theta0 = params$theta0,
        mH = params$mH,
        bH = params$bH,
        mW = params$mW,
        bW = params$bW
      )
      f_wt_vals <- unname(fwt[wt_keys])
      annual_consumption / sum(h_vals * f_wt_vals)
    },
    numeric(1L)
  )

  out
}
