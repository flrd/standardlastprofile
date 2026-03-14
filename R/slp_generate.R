#' Generate a Standard Load Profile
#'
#' Generate a standard load profile, normalised to an annual
#' consumption of 1,000 kWh.
#'
#' @param profile_id load profile identifier, required
#' @param start_date start date in ISO 8601 format greater or equal
#'   to `"1990-01-01"`, required
#' @param end_date end date in ISO 8601 format, no later than
#'   `"2073-12-31"`, required
#' @param holidays an optional character or Date vector of dates in ISO 8601
#'   format (`"YYYY-MM-DD"`) that are treated as public holidays (and therefore
#'   mapped to `"sunday"` in the algorithm). When supplied, the built-in
#'   holiday data are ignored entirely and only the dates in `holidays` are
#'   used.
#' @param state_code `r lifecycle::badge("deprecated")` Use `holidays` instead.
#'
#' @return A data.frame with four variables:
#' - `profile_id`, character, load profile identifier
#' - `start_time`, POSIXct / POSIXlt, start time
#' - `end_time`, POSIXct / POSIXlt, end time
#' - `watts`, numeric, average electric power in watts per 15-minute interval,
#'   normalised to an annual consumption of 1,000 kWh/a
#'
#' @details
#' In the German electricity market, a standard load profile is a
#' representative pattern of electricity consumption used to forecast demand
#' for customer groups that are not continuously metered. For each distinct
#' combination of `profile_id`, `period`, and `day` there are 96 quarter-hourly
#' measurements of electrical power, normalised to an annual consumption of
#' 1,000 kWh. This function supports data from 1990 to 2073.
#' See also `vignette("algorithm-step-by-step")`.
#'
#' ## Profile IDs
#'
#' There are 16 profile IDs across two generations:
#'
#' **1999 profiles**:
#'
#' - `H0`: Households
#' - `G0`, `G1`, `G2`, `G3`, `G4`, `G5`, `G6`: Commercial
#' - `L0`, `L1`, `L2`: Agriculture
#'
#' **2025 profiles**
#'
#' In 2025, BDEW published an updated set of standard load profiles reflecting
#' changes in electricity consumption patterns since the original 1999 study. Five
#' new profiles are included:
#'
#' - `H25`: households — updated version of `H0`
#' - `G25`: commerce (general) — updated version of `G0`
#' - `L25`: agriculture — updated version of `L0`
#' - `P25`: combination profile for households with a photovoltaic (PV) system
#' - `S25`: combination profile for households with a PV system and battery storage
#'
#' For descriptions of each profile, call [slp_info()].
#'
#' ## Periods and day types
#'
#' **1999 profiles** use three seasonal periods:
#' - `summer`: May 15 to September 14
#' - `winter`: November 1 to March 20
#' - `transition`: March 21 to May 14, and September 15 to October 31
#'
#' **2025 profiles** use calendar months (`january` … `december`) instead of
#' seasons.
#'
#' Within each period, days are classified as:
#' - `workday`: Monday to Friday
#' - `saturday`: Saturdays; Dec 24th and Dec 31st are also treated as Saturdays
#'   unless they fall on a Sunday
#' - `sunday`: Sundays and all public holidays
#'
#' ## Public holidays
#'
#' By default, the following nine public holidays observed nationwide across
#' all German states are treated as Sundays:
#'
#' - New Year's Day (1 January)
#' - Good Friday
#' - Easter Monday
#' - Labour Day (1 May)
#' - Ascension Day
#' - Whit Monday
#' - German Unity Day (3 October)
#' - Christmas Day (25 December)
#' - Boxing Day (26 December)
#'
#' State-level holidays are **not** included by default. These vary by state
#' and can change — for example, Berlin observed a one-time holiday on
#' 8 May 2025 (end of World War II anniversary). Use the `holidays` argument
#' to supply your own dates instead; the built-in data are then ignored
#' entirely.
#'
#' ## Units and conversion
#'
#' The 1999 source file stores values in watts (W), normalised to 1,000 kWh/a.
#' The 2025 source file stores values in kWh per 15-minute interval, normalised
#' to 1,000,000 kWh/a. To keep all profiles consistent and backwards
#' compatible, the 2025 values are converted to watts normalised to 1,000 kWh/a.
#'
#' To convert to energy consumed per interval in kWh:
#'
#' ```r
#' kwh <- out$watts / 4 / 1000
#' ```
#'
#' @source <https://www.bdew.de/energie/standardlastprofile-strom/>
#' @source <https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf>
#' @source <https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf>
#'
#' @importFrom lifecycle deprecated
#' @export
#' @examples
#' start <- "2026-01-01"
#' end <- "2026-12-31"
#'
#' # multiple profile IDs are supported
#' L <- slp_generate(c("L0", "L1", "L2"), start, end)
#' head(L)
#'
#' # supply custom holiday dates (e.g. only treat New Year's Day as a holiday)
#' H0_custom <- slp_generate("H0", start, end, holidays = "2026-01-01")
#'
#' # Fetch state-level holidays from the nager.Date API and pass them in.
#' # Each entry in the API response contains two relevant fields:
#' #   $global  — logical; TRUE = nationwide holiday, FALSE = state-specific
#' #   $counties — list of ISO 3166-2 state codes (e.g. "DE-BE" for Berlin)
#' #               when global is FALSE; NULL otherwise
#' #
#' # Berlin (DE-BE) observes International Women's Day (March 8) in addition
#' # to all nationwide holidays. The example below fetches 2027 holidays,
#' # keeps entries where global is TRUE or "DE-BE" appears in counties, and
#' # passes the resulting dates to slp_generate().
#' \dontrun{
#' resp <- httr2::request("https://date.nager.at/api/v3") |>
#'   httr2::req_url_path_append("PublicHolidays", "2027", "DE") |>
#'   httr2::req_perform() |>
#'   httr2::resp_body_json()
#'
#' is_berlin <- function(x) isTRUE(x$global) || "DE-BE" %in% unlist(x$counties)
#' holidays_berlin_2027 <- as.Date(
#'   vapply(Filter(is_berlin, resp), function(x) x$date, character(1))
#' )
#'
#' H0_berlin_2027 <- slp_generate(
#'   "H0", "2027-01-01", "2027-12-31",
#'   holidays = holidays_berlin_2027
#' )
#' }
#'
#' # consider only nationwide public holidays (default)
#' H0_2026 <- slp_generate("H0", start, end)
#'
#' # electric power values are normalised to consumption of ~1,000 kWh/a
#' sum(H0_2026$watts / 4 / 1000)
#'
#' # convert watts to kWh per interval using a wrapper
#' slp_generate_kwh <- function(...) {
#'   out <- slp_generate(...)
#'   out$kwh <- out$watts / 4 / 1000
#'   out
#' }
#' H0_kwh <- slp_generate_kwh("H0", start, end)
#' head(H0_kwh)
#'
slp_generate <- function(
  profile_id,
  start_date,
  end_date,
  holidays = NULL,
  state_code = deprecated()
) {
  if (lifecycle::is_present(state_code)) {
    lifecycle::deprecate_warn("1.1.0", "slp_generate(state_code)", "slp_generate(holidays)")
  } else {
    state_code <- NULL
  }

  start <- as_date(start_date)
  end <- as_date(end_date)

  if (anyNA(c(start, end))) {
    stop("Please provide a valid date in ISO 8601 format")
  }

  if (start < as_date("1990-01-01") || end > as_date("2073-12-31")) {
    stop("Date range must be between 1990-01-01 and 2073-12-31.")
  }

  profile_id <- match_profile(profile_id)
  profiles_n <- length(profile_id)

  if (!is.null(holidays)) {
    holidays <- as_date(holidays)
    if (anyNA(holidays)) {
      stop("'holidays' must contain valid dates in ISO 8601 format.")
    }
  }

  if (!is.null(state_code)) {
    # just in case
    state_code <- toupper(state_code)

    # users can provide state code without leading "DE-", for convenience
    if (state_code %in% c("BW", "BY", "ST", "BE", "MV", "SL", "RP", "NW", "HE", "SH", "NI", "BB", "HH", "HB", "SN", "TH")) {
      state_code <- standardise_state_names(state_code)
    }

    state_code <- match.arg(
      state_code,
      choices = c("DE-BW", "DE-BY", "DE-ST", "DE-BE", "DE-MV", "DE-SL", "DE-RP", "DE-NW", "DE-HE", "DE-SH", "DE-NI", "DE-BB", "DE-HH", "DE-HB", "DE-SN", "DE-TH")
    )
  }

  # returns vector of class 'Date'
  daily_seq <- get_daily_sequence(start_date, end_date)

  # subset of load_profiles_lst
  tmp <- load_profiles_lst[profile_id]

  vals <- vector("list", length = profiles_n)
  names(vals) <- profile_id

  # 1999 profiles use period-based matrix columns (e.g. "saturday_winter")
  profiles_1999 <- intersect(profile_id, c("H0", "G0", "G1", "G2", "G3", "G4", "G5", "G6", "L0", "L1", "L2"))
  if (length(profiles_1999) > 0L) {
    wkday_period <- get_wkday_period(daily_seq, state_code = state_code, holidays = holidays)
    for (profile in profiles_1999) {
      vals[[profile]] <- tmp[[profile]][, wkday_period]
    }
  }

  # 2025 profiles use month-based matrix columns (e.g. "saturday_january")
  profiles_2025 <- intersect(profile_id, c("H25", "G25", "L25", "P25", "S25"))
  if (length(profiles_2025) > 0L) {
    wkday_month <- get_wkday_month(daily_seq, state_code = state_code, holidays = holidays)
    for (profile in profiles_2025) {
      vals[[profile]] <- tmp[[profile]][, wkday_month]
    }
  }

  # apply dynamization to profiles where electricity consumption varies
  # by day of year, see: page 18f.
  # https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf
  dynamic_profiles <- intersect(profile_id, c("H0", "H25", "P25", "S25"))
  if (length(dynamic_profiles) > 0L) {
    days_decimal <- as.integer(format_j(daily_seq))
    dyn_factors <- dynamization_fun(days_decimal)
    for (profile in dynamic_profiles) {
      mat <- vals[[profile]]
      vals[[profile]] <- suppressWarnings(
        mat * rep(dyn_factors, each = dim(mat)[[1L]])
      )
    }
  }

  # timestamp for output
  time_seq <- get_15min_seq(start, end + 1)
  time_seq_n <- length(time_seq)

  out <- data.frame(
    profile_id = rep(profile_id, each = time_seq_n - 1L),
    start_time = rep(time_seq[-time_seq_n], profiles_n),
    end_time = rep(time_seq[-1], profiles_n),
    watts = unlist(vals, use.names = FALSE)
  )

  out
}
