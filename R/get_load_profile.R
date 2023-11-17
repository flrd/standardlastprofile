#' Generate a load profile
#'
#' `get_load_profile()` returns a load profiles in the form of quarter-hourly
#' values (in Watt) that are standardised to an annual consumption of 1,000 kWh.
#'
#' @param profile Name of the load profile, see 'Details'.
#' @param start_date starting date in ISO 8601 date format, required
#' @param end_date end date in ISO 8601 date format, required
#'
#' @details
#' Given a start and end date, each day is first mapped to a combination of workday,
#' Saturday, Sunday and a period, i.e. summer, winter, transition - the result is
#' a so-called "type day". The values for each period, day, and profile can be
#' taken from the `load_profile` data set.
#'
#' Supported profiles are:
#' - `H0`: households (German: "Haushalte")
#' - `G0` to `G6`: commerce ("Gewerbe")
#' - `L0` to `L2`: agriculture ("Landwirtschaft")
#'
#' Call [get_load_profile_info()] for more information about profiles.
#'
#'Each day is mapped to one of the three values below:
#'- `saturday`: Saturdays; Dec 24th and Dec 31th are considered a Saturday too,
#'if they are not a Sunday
#'- `sunday`: Sundays and all public holidays
#'- `workday`: Monday to Friday
#'
#'Periods as defined by the BDEW:
#'- `summer`: May 15 to September 14
#'- `winter`: November 1 to March 20
#'- `transition`: March 21 to May 14, and September 15 to October 31
#'
#' See: <https://www.bdew.de/energie/standardlastprofile-strom/> for the
#' methodology used to determine the profiles.
#'
#' @return A data.frame with three columns:
#' - `start_time`, class POSIXlt
#' - `end_time`, class POSIXlt
#' - `watt`, numeric
#'
#' @export
#' @examples
#' today <- Sys.Date()
#' get_load_profile("H0", today, today + 1) |> head()
#'
get_load_profile <- function(
    profile = c("H0", "G0", "G1", "G2", "G3", "G4", "G5", "G6", "L0", "L1", "L2"),
    start_date,
    end_date) {

  profile <- toupper(profile)
  profile <- match.arg(arg = profile)

  # returns vector of class 'Date'
  daily_seq <- get_daily_sequence(start_date, end_date)
  start <- daily_seq[1]
  end <- daily_seq[length(daily_seq)]

  # given a date, returns a 'tpye day', i.e.
  # a combination of weekday and period
  wkday_period <- get_wkday_period(daily_seq)

  # timestamps for output
  time_seq <- get_15min_seq(start, end + 1)
  time_seq_n <- length(time_seq)

  # extraxt values from internal 'load_profiles_lst' object
  values <- load_profiles_lst[[profile]][, wkday_period]

  data.frame(
    start_time = time_seq[-time_seq_n],
    end_time = time_seq[-1L],
    watt = as.vector(values)
  )
}



