#' Generate a Standard Load Profile for Electricity
#'
#' Generate a standard load profile in watts, normalised to an annual
#' consumption of 1,000 kWh.
#'
#' @param profile_id load profile identifier, required
#' @param start_date start date in ISO 8601 format, required
#' @param end_date end date in ISO 8601 format, required
#' @param holidays controls public holiday treatment:
#'   - `NULL` (default): built-in nationwide German holidays are used.
#'   - `NA`: no dates are treated as public holidays.
#'   - a character or Date vector in ISO 8601 format (`"YYYY-MM-DD"`): only
#'     these dates are treated as public holidays; the built-in data are
#'     ignored entirely.
#'
#' @return A data.frame with four variables:
#' - `profile_id`, character, load profile identifier
#' - `start_time`, POSIXct / POSIXlt, start time
#' - `end_time`, POSIXct / POSIXlt, end time
#' - `watts`, numeric, average electric power in watts per 15-minute interval,
#'   normalised to an annual consumption of 1,000 kWh
#'
#' @details
#' In the German electricity market, a standard load profile is a
#' representative pattern of electricity consumption used to forecast demand
#' for customer groups that are not continuously metered. For each distinct
#' combination of `profile_id`, `period`, and `day` there are 96 quarter-hourly
#' measurements of electrical power, normalised to an annual consumption of
#' 1,000 kWh.
#'
#' See the
#' \href{https://flrd.github.io/standardlastprofile/articles/slp-electricity.html}{electricity algorithm}
#' article for more details.
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
#' - `H25`: Households — updated version of `H0`
#' - `G25`: Commercial (general) — updated version of `G0`
#' - `L25`: Agriculture — updated version of `L0`
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
#' The built-in holiday data cover the years 1990 to 2099. For dates outside
#' this range, `holidays = NULL` will yield no public holiday adjustments; pass
#' `holidays` explicitly if needed.
#'
#' ## Units and conversion
#'
#' The 1999 source file stores values in watts (W), normalised to 1,000 kWh/a.
#' The 2025 source file stores values in kWh per 15-minute interval, normalised
#' to 1,000,000 kWh/a. To keep all profiles consistent, the 2025 values
#' are converted to watts normalised to 1,000 kWh/a.
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
#' @export
#' @examples
#' start <- "2026-01-01"
#' end <- "2026-12-31"
#'
#' # multiple profile IDs are supported
#' L <- slp_electricity(c("L0", "L1", "L2"), start, end)
#' head(L)
#'
#' # supply custom holiday dates (e.g. only treat New Year's Day as a holiday)
#' H0_custom <- slp_electricity("H0", start, end, holidays = "2026-01-01")
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
#' # passes the resulting dates to slp_electricity().
#' \dontrun{
#' resp <- httr2::request("https://date.nager.at/api/v3") |>
#'   httr2::req_url_path_append("PublicHolidays", "2027", "DE") |>
#'   httr2::req_perform() |>
#'   httr2::resp_body_json()
#'
#' is_berlin <- \(x) isTRUE(x$global) || "DE-BE" %in% unlist(x$counties)
#' holidays_berlin_2027 <- as.Date(
#'   vapply(Filter(is_berlin, resp), \(x) x$date, character(1))
#' )
#'
#' H0_berlin_2027 <- slp_electricity(
#'   "H0", "2027-01-01", "2027-12-31",
#'   holidays = holidays_berlin_2027
#' )
#' }
#'
#' # consider only nationwide public holidays (default)
#' H0_2026 <- slp_electricity("H0", start, end)
#'
#' # electric power values are normalised to consumption of ~1,000 kWh/a
#' sum(H0_2026$watts / 4 / 1000)
#'
#' # convert watts to kWh per interval using a wrapper
#' slp_generate_kwh <- \(...) {
#'   out <- slp_electricity(...)
#'   out$kwh <- out$watts / 4 / 1000
#'   out
#' }
#' H0_kwh <- slp_generate_kwh("H0", start, end)
#' head(H0_kwh)
#'
slp_electricity <- \(
  profile_id,
  start_date,
  end_date,
  holidays = NULL
) {
  if (is.null(start_date)) {
    stop(
      "'start_date' is missing; please provide a date in ISO 8601 format (\"YYYY-MM-DD\")."
    )
  }
  if (is.null(end_date)) {
    stop(
      "'end_date' is missing; please provide a date in ISO 8601 format (\"YYYY-MM-DD\")."
    )
  }
  if (length(start_date) != 1L) {
    stop("'start_date' must be of length 1.")
  }
  if (length(end_date) != 1L) {
    stop("'end_date' must be of length 1.")
  }

  if (
    is.character(start_date) && !grepl("^\\d{4}-\\d{2}-\\d{2}$", start_date)
  ) {
    stop(
      "'start_date' must be a valid date in ISO 8601 format (\"YYYY-MM-DD\")."
    )
  }
  if (is.character(end_date) && !grepl("^\\d{4}-\\d{2}-\\d{2}$", end_date)) {
    stop("'end_date' must be a valid date in ISO 8601 format (\"YYYY-MM-DD\").")
  }

  start <- .as_date(start_date)
  end <- .as_date(end_date)

  if (is.na(start)) {
    stop(
      "'start_date' must be a valid date in ISO 8601 format (\"YYYY-MM-DD\")."
    )
  }
  if (is.na(end)) {
    stop("'end_date' must be a valid date in ISO 8601 format (\"YYYY-MM-DD\").")
  }

  profile_id <- .match_profile(profile_id)
  profiles_n <- length(profile_id)

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
      is.character(holidays) && !all(grepl("^\\d{4}-\\d{2}-\\d{2}$", holidays))
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

  # returns vector of class 'Date'
  daily_seq <- .get_daily_sequence(start_date, end_date)

  profiles_1999_set <- c(
    "H0",
    "G0",
    "G1",
    "G2",
    "G3",
    "G4",
    "G5",
    "G6",
    "L0",
    "L1",
    "L2"
  )
  dynamic_set <- c("H0", "H25", "P25", "S25")

  # column keys per day, computed once (only what is needed):
  # 1999 profiles use period-based columns (e.g. "saturday_winter"),
  # 2025 profiles use month-based columns (e.g. "saturday_january").
  any_1999 <- any(profile_id %in% profiles_1999_set)
  any_2025 <- !all(profile_id %in% profiles_1999_set)
  wkday_period <- if (any_1999) {
    .get_wkday_period(daily_seq, holidays = holidays)
  }
  wkday_month <- if (any_2025) {
    .get_wkday_month(daily_seq, holidays = holidays)
  }

  # dynamization factor per day (H0 and the dynamic 2025 profiles), see p. 18f.
  # https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf
  dyn_factors <- .dynamization_fun(as.integer(.format_j(daily_seq)))

  # build per profile by position, so duplicate profile_id values are kept
  # and returned faithfully (rather than collapsed by a named list).
  vals <- vector("list", length = profiles_n)
  for (i in seq_along(profile_id)) {
    pid <- profile_id[[i]]
    key <- if (pid %in% profiles_1999_set) wkday_period else wkday_month
    # drop = FALSE keeps a 96 x n_days matrix even for a single day
    mat <- load_profiles_lst[[pid]][, key, drop = FALSE]
    if (pid %in% dynamic_set) {
      mat <- mat * rep(dyn_factors, each = nrow(mat))
    }
    vals[[i]] <- as.vector(mat)
  }

  # timestamp for output
  time_seq <- .get_15min_seq(start, end + 1)
  time_seq_n <- length(time_seq)

  out <- data.frame(
    profile_id = rep(profile_id, each = time_seq_n - 1L),
    start_time = rep(time_seq[-time_seq_n], profiles_n),
    end_time = rep(time_seq[-1], profiles_n),
    watts = unlist(vals, use.names = FALSE)
  )

  out
}
