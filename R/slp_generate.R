#' Generate a Standard Load Profile
#'
#' Generate a standard load profile, normalized to an annual
#' consumption of 1,000 kWh.
#'
#' @param profile_id load profile identifier, required
#' @param start_date start date in ISO 8601 format, required
#' @param end_date end date in ISO 8601 format, required
#' @param holidays an optional character or Date vector of dates in ISO 8601
#'   format (`"YYYY-MM-DD"`) that are treated as public holidays (and therefore
#'   mapped to `"sunday"` in the algorithm). When supplied, the built-in
#'   holiday data are ignored entirely and only the dates in `holidays` are
#'   used.
#' @param unit one of `"W"` (default) or `"KWH"`. Controls the unit of the
#'   returned `watts` column. `"W"` returns average electric power in watts
#'   for each 15-minute interval. `"KWH"` converts to energy consumed during
#'   each interval in kilowatt-hours (`watts * 0.25 / 1000`). Matching is
#'   case-insensitive, so `"kWh"` is accepted.
#' @param state_code `r lifecycle::badge("deprecated")` Use `holidays` instead.
#'
#' @return A data.frame with four variables:
#' - `profile_id`, character, load profile identifier
#' - `start_time`, POSIXct / POSIXlt, start time
#' - `end_time`, POSIXct / POSIXlt, end time
#' - `watts`, numeric, electric power
#'
#' @details
#' In regards to the electricity market in Germany, the term "Standard Load
#' Profile" refers to a representative pattern of electricity consumption over
#' a specific period. These profiles can be used to depict the expected electricity
#' consumption for various customer groups, such as households or businesses.
#'
#' For each distinct combination of `profile_id`, `period`, and `day`, there
#' are 96 x 1/4 hour measurements of electrical power. Values are normalized so
#' that they correspond to an annual consumption of 1,000 kWh. That is, summing
#' up all the quarter-hourly consumption values for one year yields an approximate
#' total of 1,000 kWh/a; for more information, refer to the 'Examples' section,
#' or call `vignette("algorithm-step-by-step")`.
#'
#' In total there are 11 `profile_id` for three different customer groups:
#'
#' - Households: `H0`
#' - Commercial: `G0`, `G1`, `G2`, `G3`, `G4`, `G5`, `G6`
#' - Agriculture: `L0`, `L1`, `L2`
#'
#' For more information and examples, call [slp_info()].
#'
#' Period definitions:
#' - `summer`: May 15 to September 14
#' - `winter`: November 1 to March 20
#' - `transition`: March 21 to May 14, and September 15 to October 31
#'
#' Day definitions:
#' - `workday`: Monday to Friday
#' - `saturday`: Saturdays; Dec 24th and Dec 31st are considered Saturdays too
#'if they are not a Sunday
#' - `sunday`: Sundays and all public holidays
#'
#' **Note**: By default, the package uses built-in nationwide public holiday
#' data for Germany (1990–2073). Use `holidays` to supply your own set of
#' holiday dates instead.
#'
#' `start_date` must be greater or equal to "1990-01-01" and `end_date` must
#' be smaller or equal to "2073-12-31".
#'
#' @source <https://www.bdew.de/energie/standardlastprofile-strom/>
#' @source <https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf>
#' @source <https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf>
#'
#' @importFrom lifecycle deprecated
#' @export
#' @examples
#' start <- "2024-01-01"
#' end <- "2024-12-31"
#'
#' # multiple profile IDs are supported
#' L <- slp_generate(c("L0", "L1", "L2"), start, end)
#' head(L)
#'
#' # supply custom holiday dates (e.g. only treat New Year's Day as a holiday)
#' H0_custom <- slp_generate("H0", start, end, holidays = "2024-01-01")
#'
#' # consider only nationwide public holidays (default)
#' H0_2024 <- slp_generate("H0", start, end)
#'
#' # electric power values are normalized to consumption of ~1,000 kWh/a
#' sum(H0_2024$watts / 4 / 1000)
#'
slp_generate <- function(
    profile_id,
    start_date,
    end_date,
    holidays = NULL,
    unit = "W",
    state_code = deprecated()) {

  unit <- match.arg(toupper(unit), choices = c("W", "KWH"))

  if (lifecycle::is_present(state_code)) {
    lifecycle::deprecate_warn("1.1.0", "slp_generate(state_code)", "slp_generate(holidays)")
  } else {
    state_code <- NULL
  }

  start <- as_date(start_date)
  end <- as_date(end_date)

  if(anyNA(c(start, end))) {
    stop("Please provide a valid date in ISO 8601 format")
  }

  if(start < as_date("1990-01-01") || end > as_date("2073-12-31")) {
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

  if(!is.null(state_code)) {

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
    dyn_factors  <- dynamization_fun(days_decimal)
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

  if (unit == "KWH") {
    out$watts <- out$watts * 0.25 / 1000
  }

  out
}
