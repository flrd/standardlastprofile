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
#'   days. Must have the same length as `temperatures`. When both
#'   `dates`/`temperatures` and `station` are supplied,
#'   `dates`/`temperatures` take precedence.
#' @param temperatures a numeric vector of daily temperatures in degrees
#'   Celsius. Must have the same length as `dates`.
#' @param station character scalar, name of a built-in DWD reference weather
#'   station. One of `"Oberstdorf"`, `"Potsdam"`, `"Hamburg"`, `"Freiburg"`,
#'   `"Chemnitz"`, `"Duesseldorf"`, `"Erfurt"`, `"Frankfurt"`, `"Nuernberg"`,
#'   or `"Regensburg"`. When supplied (and `dates`/`temperatures` are
#'   `NULL`), the long-term mean daily temperatures (WMO climate normal period
#'   1991–2020) for that station are used as the reference series.
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
#' The Kundenwert is defined as:
#'
#' \deqn{KW = \frac{E_a}{\sum_D h(\vartheta_D) \cdot F_{WT,D}}}
#'
#' where \eqn{E_a} is `annual_consumption` and the sum runs over all days in
#' the temperature series. For the result to be meaningful the denominator must
#' reflect a full seasonal cycle; with fewer than 365 days a message is shown.
#'
#' ## Built-in reference stations
#'
#' The package ships with long-term mean daily temperatures for ten
#' representative DWD weather stations (WMO climate normal period 1991–2020).
#' Using a climatological mean avoids any single-year anomaly influencing the
#' Kundenwert. Available stations:
#'
#' | Station      | Region                     |
#' |--------------|----------------------------|
#' | Oberstdorf   | Alpenrand / Allgaeu        |
#' | Potsdam      | Kontinentales Binnenland   |
#' | Hamburg      | Maritime Nordseekueste     |
#' | Freiburg     | Oberrheingraben            |
#' | Chemnitz     | Erzgebirge / Mittelgebirge |
#' | Duesseldorf  | Niederrhein                |
#' | Erfurt       | Thueringer Becken          |
#' | Frankfurt    | Rhein-Main-Gebiet          |
#' | Nuernberg    | Mittelfranken              |
#' | Regensburg   | Oberpfalz / Donau          |
#'
#' ## Recommended workflow
#'
#' ```r
#' # Step 1 — derive KW from a built-in reference station
#' kw <- slp_gas_kundenwert("HEF", station = "Hamburg", annual_consumption = 15000)
#'
#' # Step 2 — generate a profile for any shorter period
#' slp_gas("HEF", dates_jan_mar, temps_jan_mar, kundenwert = kw)
#' ```
#'
#' Alternatively, pass your own full-year date and temperature vectors via
#' `dates` and `temperatures` (e.g. downloaded from DWD via the `rdwd`
#' package).
#'
#' @seealso [slp_gas()]
#' @export
#' @examples
#' # Using a built-in reference station
#' slp_gas_kundenwert("HEF", station = "Hamburg", annual_consumption = 15000)
#'
#' # Multiple profiles at once
#' slp_gas_kundenwert(c("HEF", "GKO", "GWA"), station = "Potsdam",
#'                    annual_consumption = 15000)
#'
#' # Using custom temperatures
#' dates_ref <- seq.Date(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "day")
#' doy       <- as.integer(format(dates_ref, "%j"))
#' temps_ref <- 10 - 11 * cos(2 * pi * (doy - 15) / 365)
#' slp_gas_kundenwert("HEF", dates = dates_ref, temperatures = temps_ref,
#'                    annual_consumption = 15000)
slp_gas_kundenwert <- \(
  profile_id,
  dates = NULL,
  temperatures = NULL,
  station = NULL,
  annual_consumption = 1000,
  variant = c("34", "33"),
  holidays = NULL
) {
  # ---- available stations (for messages and validation) ----------------------
  available_stations <- unique(slp_gas_normtemperatur$station)

  # ---- validate variant ---------------------------------------------------
  variant <- match.arg(variant)

  # ---- validate profile_id ------------------------------------------------
  profile_id <- match_profile_gas(profile_id)

  # ---- resolve dates / temperatures / station ------------------------------
  has_dates <- !is.null(dates)
  has_temps <- !is.null(temperatures)

  if (!has_dates && !has_temps && is.null(station)) {
    stop(
      "Please supply either 'dates' and 'temperatures', or 'station'. ",
      "Built-in reference stations are: ",
      paste0("\"", available_stations, "\"", collapse = ", "),
      "."
    )
  }

  if (has_dates != has_temps) {
    stop("'dates' and 'temperatures' must both be supplied or both be NULL.")
  }

  if (!has_dates && !has_temps && !is.null(station)) {
    if (!is.character(station) || length(station) != 1L) {
      stop("'station' must be a single character string.")
    }
    station_match <- match(tolower(station), tolower(available_stations))
    if (is.na(station_match)) {
      stop(
        "'station' must be one of: ",
        paste0("\"", available_stations, "\"", collapse = ", "),
        "."
      )
    }
    station_name <- available_stations[station_match]
    ref <- slp_gas_normtemperatur[
      slp_gas_normtemperatur$station == station_name,
    ]
    dates <- ref$date
    temperatures <- ref$temp_c_mean
  }

  # ---- validate dates -----------------------------------------------------
  if (is.character(dates)) {
    if (!all(grepl("^\\d{4}-\\d{2}-\\d{2}$", dates))) {
      stop(
        "'dates' must contain valid dates in ISO 8601 format (\"YYYY-MM-DD\")."
      )
    }
    dates <- as.Date(dates)
  }
  if (!is_date(dates)) {
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
    if (!is.character(holidays) && !is_date(holidays)) {
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
    holidays <- as_date(holidays)
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
  wt_keys <- get_gas_weekday_key(dates, holidays = holidays)

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
