#' Generate a Standard Load Profile for Gas
#'
#' Generate daily gas consumption values using the BDEW/VKU/GEODE synthetic
#' standard load profile procedure (SigLinDe method).
#'
#' @param profile_id gas load profile identifier, required. One of `"HEF"`,
#'   `"HMF"`, `"HKO"`, `"GKO"`, `"GHA"`, `"GMK"`, `"GBD"`, `"GBH"`,
#'   `"GWA"`, `"GGA"`, `"GBA"`, `"GGB"`, `"GPD"`, `"GMF"`, `"GHD"`.
#'   Multiple values are supported.
#' @param dates a Date vector or character vector in ISO 8601 format
#'   (`"YYYY-MM-DD"`). Each element is the **start date** of a gas day
#'   (German: *Gastag*, 06:00–06:00). Must have the same length as
#'   `temperatures`.
#' @param temperatures a numeric vector of daily temperatures in degrees
#'   Celsius, one value per gas day. Must have the same length as `dates`.
#'   The temperature should be the allocation temperature (German:
#'   *Allokationstemperatur*) for that gas day. Two options are supported by
#'   the Leitfaden (see Details):
#'   - **Simple daily mean** (*Tagesmitteltemperatur*): arithmetic average of
#'     hourly values over the gas day.
#'   - **Geometrically-weighted 4-day mean**: recommended by BDEW for
#'     distribution network operators.
#'
#'   In production contexts, distribution network operators increasingly use the
#'   **gas forecast temperature** (German: *Gasprognosetemperatur*, GPT)
#'   published by DWD or DTN instead of a raw daily mean. The GPT incorporates
#'   a multi-day weighted average and seasonal adjustment that reduces the
#'   systematic seasonal allocation bias of pure temperature-based profiles
#'   (VKU SLP evaluation reports 2023, 2025). This function accepts whichever
#'   temperature values are passed; the choice of method is the caller's
#'   responsibility.
#' @param kundenwert numeric scalar, required. Customer value (Kundenwert) in
#'   kWh/day — the daily gas consumption at the reference temperature of 8 °C.
#'   Derive it once from a full reference year with [slp_gas_kundenwert()], or
#'   supply a value you already know. See Details.
#' @param variant SigLinDe variant (German: *Ausprägung*) to use. Either `"34"`
#'   (default) or `"33"`. Variant 34 has a 57 % linear component and a
#'   steeper heating slope; variant 33 has a 45 % linear component. The
#'   BDEW Leitfaden recommends that distribution network operators test both
#'   variants against their own grid data and select the better fit.
#'   See Details.
#'
#'   The `"HKO"` profile is a pure sigmoid with no linear part and is
#'   unaffected by this argument.
#' @param holidays controls public holiday treatment:
#'   - `NULL` (default): built-in nationwide German holidays are used.
#'   - `NA`: no dates are treated as public holidays.
#'   - a character or Date vector in ISO 8601 format (`"YYYY-MM-DD"`): only
#'     these dates are treated as public holidays; the built-in data are
#'     ignored entirely.
#'
#' @return A data.frame with three variables:
#' - `profile_id`, character, gas load profile identifier
#' - `date`, Date, start date of the gas day (06:00 local time)
#' - `kwh`, numeric, estimated gas consumption in kWh for that gas day
#'
#' @details
#' ## Background
#'
#' In the (German) gas market, standard load profiles (Standardlastprofile, SLP)
#' are used to allocate gas volumes to low-pressure customers who are not
#' continuously metered. The synthetic procedure computes a daily gas
#' quantity as:
#'
#' \deqn{Q(D) = KW \times h(\vartheta_D) \times F_{WT}}
#'
#' where:
#' - \eqn{KW} is a customer-specific scaling factor in kWh/day (German: *Kundenwert*).
#' - \eqn{h(\vartheta_D)} is the SigLinDe profile function value for the
#'   daily temperature \eqn{\vartheta_D}.
#' - \eqn{F_{WT}} is the weekday factor for the profile and day type.
#'
#' ## SigLinDe Profile Function
#'
#' The SigLinDe function is defined in two variants (German: *Ausprägungen*).
#' The pure sigmoid term was introduced by TU München (Geiger / Hellwig 2002);
#' the linear envelope on top — together with the 33 / 34 variant split — was
#' added by FfE in the 2015 research report *Weiterentwicklung des Standard-
#' lastprofilverfahrens Gas* (Appendix 7.1). The current operational coefficient
#' set is published in the BDEW Leitfaden, Appendix 6 (as of 2025-10-28):
#'
#' \deqn{h(\vartheta) = \frac{A}{1 + \left(\frac{B}{\vartheta - \vartheta_0}\right)^C} + D + \max(m_H \vartheta + b_H,\; m_W \vartheta + b_W)}
#'
#' The first four terms form the sigmoid part; the last term is the linear
#' part (space-heating and hot water lines). Variant 34 (57 % linear
#' component, steeper heating slope) is the default. Variant 33 (45 % linear
#' component) is an alternative for distribution network areas where it fits
#' better. Distribution network operators are advised to test both against
#' their own grid data.
#'
#' The `HKO` profile (Kochgasprofil) is a pure sigmoid retained from the
#' pre-SigLinDe era; it has no 33/34 variant and its linear part is always
#' zero.
#'
#' ## Allocation temperature
#'
#' The allocation temperature can be computed in two ways:
#'
#' **Simple daily mean** — arithmetic mean of hourly temperatures:
#' \deqn{\vartheta_D = \frac{1}{24} \sum_{h=1}^{24} T_h}
#'
#' **Geometrically-weighted 4-day mean** (recommended by BDEW for network
#' operators):
#' \deqn{\vartheta_D = \frac{T_D + 0.5 \times T_{D-1} + 0.25 \times T_{D-2} + 0.125 \times T_{D-3}}{1.875}}
#'
#' This function accepts whichever temperature values the user provides in
#' `temperatures`; the choice of method is the user's responsibility.
#'
#' ## Kundenwert
#'
#' The Kundenwert \eqn{KW} scales the dimensionless profile to a customer's
#' actual consumption and is a **required** input. The recommended workflow is
#' two steps:
#'
#' 1. Derive \eqn{KW} once from a full reference year of temperatures with
#'    [slp_gas_kundenwert()]:
#'    \deqn{KW = \frac{E_a}{\sum_D h(\vartheta_D) \times F_{WT,D}}}
#'    where \eqn{E_a} is the annual consumption.
#' 2. Pass that \eqn{KW} to `slp_gas()` for any period you want to generate.
#'
#' Keeping the two steps separate is deliberate: `kundenwert` is a property
#' of the customer and their climate zone, computed from a representative
#' (ideally multi-year) temperature mean. Deriving it from the same short
#' series you are generating over would collapse the seasonal denominator and
#' bias the result — for a single day the \eqn{h} values cancel entirely.
#'
#' ## Profile IDs
#'
#' There are 15 gas profile IDs defined in the BDEW Leitfaden:
#'
#' **Residential**:
#' - `HEF`: single-family home (Einfamilienhaus)
#' - `HMF`: multi-family home (Mehrfamilienhaus)
#' - `HKO`: cooking and hot water only (Kochen / Warmwasser)
#'
#' **Commercial / industrial**:
#' - `GKO`: small commercial (Kleinstgewerbe)
#' - `GHA`: trade and commerce (Handel)
#' - `GMK`: metal and automotive (Metall / Kfz)
#' - `GBD`: services (Dienstleistung)
#' - `GBH`: accommodation (Beherbergung)
#' - `GWA`: laundries (Wäscherei)
#' - `GGA`: gastronomy (Gastronomie)
#' - `GBA`: bakeries (Bäckerei)
#' - `GGB`: mixed commercial (gemischtes Gewerbe)
#' - `GPD`: paper and printing (Papier / Druck)
#' - `GMF`: large multi-family / mixed use (Mehrfamilienhaus groß)
#' - `GHD`: trade, commerce and services aggregate (GHD-Stützpunkt)
#'
#' ## Weekday Factors
#'
#' Unlike the electricity profiles, gas weekday factors use seven individual
#' weekdays (Mo, Tu, We, Th, Fr, Sa, Su) rather than three day types. Public
#' holidays are treated as Sunday (`Su`); 24 December and 31 December are
#' treated as Saturday (`Sa`) unless they fall on a Sunday.
#'
#' For the residential profiles `HEF`, `HMF`, and `HKO` all weekday factors
#' are 1, meaning no day-of-week differentiation is applied.
#'
#' The built-in holiday data cover the years 1990 to 2099. For dates outside
#' this range, `holidays = NULL` will yield no public holiday adjustments; pass
#' `holidays` explicitly if needed.
#'
#' @source <https://www.bdew.de/energie/standardlastprofile-gas/>
#' @source BDEW/VKU/GEODE. *Leitfaden Abwicklung von Standardlastprofilen
#'   Gas*, Kooperationsvereinbarung Gas, Annex XIV.2, as of 2025-10-28,
#'   Appendix 6.
#'   \url{https://www.bdew.de/media/documents/251028_LF_SLP_Gas_KoV_XIV.2.pdf}
#'
#' @seealso [slp_gas_kundenwert()] to derive the `kundenwert`;
#'   [slp_gas_coefficients()] and [slp_gas_siglinde()] for the underlying
#'   coefficients and profile function.
#'
#' @export
#' @examples
#' dates <- seq.Date(as.Date("2026-01-01"), as.Date("2026-01-07"), by = "day")
#' temps <- c(2.1, -1.3, 0.5, 3.8, 5.2, 4.0, 1.9)
#'
#' # Supply the Kundenwert directly (kWh/day)
#' slp_gas("HEF", dates, temps, kundenwert = 55.1)
#'
#' # Multiple profiles
#' slp_gas(c("HEF", "HMF", "GKO"), dates, temps, kundenwert = 55.1)
slp_gas <- \(
  profile_id,
  dates,
  temperatures,
  kundenwert,
  variant = c("34", "33"),
  holidays = NULL
) {
  # ---- validate variant ---------------------------------------------------
  variant <- match.arg(variant)
  # ---- validate profile_id ------------------------------------------------
  profile_id <- .match_profile_gas(profile_id)
  profiles_n <- length(profile_id)

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

  # ---- validate kundenwert ------------------------------------------------
  if (missing(kundenwert) || is.null(kundenwert)) {
    stop(
      "'kundenwert' is required. Derive it from a full reference year with ",
      "`slp_gas_kundenwert()`, or supply a value you already know."
    )
  }
  if (
    !is.numeric(kundenwert) ||
      length(kundenwert) != 1L ||
      !is.finite(kundenwert) ||
      kundenwert < 0
  ) {
    stop("'kundenwert' must be a single finite non-negative numeric value.")
  }

  # ---- validate holidays --------------------------------------------------
  # NA means "no holidays at all" — convert to empty Date vector so the
  # built-in data are skipped and nothing is treated as a public holiday.
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

  # ---- compute weekday keys -----------------------------------------------
  wt_keys <- .get_gas_weekday_key(dates, holidays = holidays)

  # ---- build output -------------------------------------------------------
  out_list <- vector("list", length = profiles_n)

  for (i in seq_along(profile_id)) {
    pid <- profile_id[[i]]
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

    out_list[[i]] <- data.frame(
      profile_id = pid,
      date = dates,
      kwh = kundenwert * h_vals * f_wt_vals
    )
  }

  do.call(rbind, out_list)
}
