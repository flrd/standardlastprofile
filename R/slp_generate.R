#' Generate a Standard Load Profile
#'
#' Generate a standard load profile, normalized to an annual
#' consumption of 1,000 kWh.
#'
#' @param profile_id load profile identifier, required
#' @param start_date start date in ISO 8601 format, required
#' @param end_date end date in ISO 8601 format, required
#' @param state_code identifier for one of 16 German states, optional
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
#' a specific period, based on average consumption data. These profiles are used
#' to depict the expected electricity consumption for various customer groups,
#' such as households or businesses.
#'
#' For every day, there are 96 x 1/4 hour measurements of electrical power for
#' each distinct combination of `profile_id`, `period` and `day`. Values are
#' normalized so that they correspond to an annual consumption of 1,000 kWh.
#' Summing up all the quarter-hourly consumption values for one year yields
#' an approximate total of 1,000 kWh/a; for more information, refer to the
#' 'Examples' section and call `vignette("algorithm-step-by-step")`.
#'
#' In total there are 11 representative, standard load profiles for three
#' different customer groups:
#'
#'- Households: `H0`
#'- Commercial: `G0`, `G1`, `G2`, `G3`, `G4`, `G5`, `G6`
#'- Agriculture: `L0`, `L1`, `L2`
#'
#'For more information and examples, call [slp_info()].
#'
#'Period definitions:
#'- `summer`: May 15 to September 14
#'- `winter`: November 1 to March 20
#'- `transition`: March 21 to May 14, and September 15 to October 31
#'
#'Characteristic day definitions:
#'- `saturday`: Saturdays; Dec 24th and Dec 31th are considered a Saturdays too
#'if they are not a Sunday.
#'- `sunday`: Sundays and all public holidays.
#'- `workday`: Monday to Friday.
#'
#'**Note**: The package supports nationwide public holidays for Germany,
#'retrieved from the [nager.Date API](https://github.com/nager/Nager.Date).
#'Use the optional argument `state_code` to consider public holidays on a state
#'level too. Possible values are listed below:
#'
#' - `DE-BB`: Brandenburg
#' - `DE-BE`: Berlin
#' - `DE-BW`: Baden-Württemberg
#' - `DE-BY`: Bavaria
#' - `DE-HB`: Bremen
#' - `DE-HE`: Hesse
#' - `DE-HH`: Hamburg
#' - `DE-MV`: Mecklenburg-Vorpommern
#' - `DE-NI`: Lower-Saxony
#' - `DE-NW`: North Rhine-Westphalia
#' - `DE-RP`: Rhineland-Palatinate
#' - `DE-SH`: Schleswig-Holstein
#' - `DE-SL`: Saarland
#' - `DE-SN`: Saxony
#' - `DE-ST`: Saxony-Anhalt
#' - `DE-TH`: Thuringia
#'
#' `start_date` must be greater or equal to "1990-01-01". This is because public
#'  holidays in Germany would be ambitious before the reunification in 1990
#'  (think of the state of Berlin in 1989 and before).
#'
#' `end_date` must be smaller or equal to "2073-12-31" because this is last
#' year supported by the [nager.Date API](https://github.com/nager/Nager.Date).
#'
#' @source <https://www.bdew.de/energie/standardlastprofile-strom/>
#' @source <https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf>
#' @source <https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf>
#'
#' @export
#' @examples
#' today <- Sys.Date()
#'
#' # mulitple profile IDs are supported
#' L <- slp_generate(c("L0", "L1", "L2"), today, today + 1)
#' head(L)
#'
#' # Electric power values are normalized to an annual consumption of 1,000 kWh
#' H0_2024 <- slp_generate("H0", "2024-01-01", "2024-12-31")
#' sum(H0_2024$watts / 4 / 1000)
#'
#' # you can supply one of 16 ISO 3166-2:DE state codes for each German state
#' \dontrun{
#' slp_generate("H0", "2024-01-01", "2024-12-31", state = "DE-BE")
#'
#' # with or without "DE-" prefix, case-insensitive
#' slp_generate("H0", "2024-01-01", "2024-12-31", state = "BE")
#' slp_generate("H0", "2024-01-01", "2024-12-31", state_code = "de-be") # all Berlin
#'
#' # if no state code is provided then only nationwide public holidays are considered
#' slp_generate("H0", "2024-01-01", "2024-12-31")
#' }
slp_generate <- function(
    profile_id,
    start_date,
    end_date,
    state_code = NULL) {

  if(missing(profile_id)) {
    stop("Please provide at least one value as 'profile_id'.")
  }

  start <- as_date(start_date)
  end <- as_date(end_date)

  if(anyNA(c(start, end))) {
    stop("Please provide a valid date in ISO 8601 format")
  }

  if(start < as_date("1990-01-01") || end > as_date("2073-12-31")) {
    stop("Supported date range must be between 1990-01-01 and 2073-12-31.")
  }

  profile_id <- toupper(profile_id)
  profile_id <- unique(profile_id)

  profile_id <- match.arg(arg = profile_id,
                          choices = c("H0", "G0", "G1", "G2", "G3", "G4", "G5", "G6", "L0", "L1", "L2"),
                          several.ok = TRUE)
  profiles_n <- length(profile_id)

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

  # given a date, returns combination of weekday and period
  wkday_period <- get_wkday_period(daily_seq, state_code = state_code)

  # subset of load_profiles_lst
  tmp <- load_profiles_lst[profile_id]

  vals <- vector("list", length = profiles_n)
  names(vals) <- profile_id

  for(profile in profile_id) {
    vals[[profile]] <- tmp[[profile]][, wkday_period]
  }

  # generate a dynamic profile for households which takes
  # into account that electricity consumption increases
  # in winter, see: page 18f.
  # https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf
  if ("H0" %in% profile_id) {
    tmp_h0 <- vals[["H0"]]

    # get day of year as decimal number
    days_decimal <- as.integer(format_j(daily_seq))

    # multiply values for each day with
    vals[["H0"]] <- suppressWarnings(
      tmp_h0 * rep(dynamization_fun(days_decimal), each = dim(tmp_h0)[[1]])
      )
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
