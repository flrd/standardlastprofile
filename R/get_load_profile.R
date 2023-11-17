#' Generate a Load Profile
#'
#' `get_load_profile()` returns load profiles in the form of quarter-hourly
#' values (in Watt) that are standardized to an annual consumption of 1,000 kWh.
#'
#' @param profiles Name of one or more load profiles, see 'Details'.
#' @param start_date starting date in ISO 8601 date format, required
#' @param end_date end date in ISO 8601 date format, required
#'
#' @details
#' Supported profiles are:
#' - `H0`: households (German: "Haushalte")
#' - `G0` to `G6`: commerce ("Gewerbe")
#' - `L0` to `L2`: agriculture ("Landwirtschaft")
#'
#' Call [get_load_profile_info()] for more information about profiles.
#'
#' The standard load profiles are differentiated according to winter,
#' transitional period and summer as well as workday, Saturday and Sunday.
#' The values for each combination of profile, period and day can be retrieved
#' from the `load_profile` dataset.
#'
#'Periods are defined as:
#'- `summer`: May 15 to September 14
#'- `winter`: November 1 to March 20
#'- `transition`: March 21 to May 14, and September 15 to October 31
#'
#'Dates are mapped to one of three days:
#'- `saturday`: Saturdays; Dec 24th and Dec 31th are considered a Saturday too,
#'if they are not a Sunday
#'- `sunday`: Sundays and all public holidays
#'- `workday`: Monday to Friday
#'
#'**Note**: As of now the package supports public holidays for Germany only. They
#'were retrieved from the [nager.Date API](https://github.com/nager/Nager.Date).
#'
#' See: <https://www.bdew.de/energie/standardlastprofile-strom/> for the
#' methodology used to determine the profiles.
#'
#' @return A data.frame with four columns:
#' - `profile` load profile identifier
#' - `date_time`, class POSIXlt
#' - `watt`, numeric
#'
#' @export
#' @examples
#' today <- Sys.Date()
#' get_load_profile("H0", today, today + 1) |> head()
#' get_load_profile(c("L0", "L1", "L2"), today, today + 1) |> head()
get_load_profile <- function(
    profiles = c("H0", "G0", "G1", "G2", "G3", "G4", "G5", "G6", "L0", "L1", "L2"),
    start_date,
    end_date) {

  start <- as_date(start_date)
  end <- as_date(end_date)

  if(anyNA(start, end)) {
    stop("Please provide a valid date in ISO 8601 format")
  }

  if(start < as.Date("1973-01-01") || end > as.Date("2073-01-01")) {
    stop("Supported date range must be between 1973-01-01 and 2072-12-31.")
  }

  profiles <- toupper(profiles)
  profiles <- unique(profiles)

  profiles <- match.arg(arg = profiles, several.ok = TRUE)
  profiles_n <- length(profiles)

  # returns vector of class 'Date'
  daily_seq <- get_daily_sequence(start_date, end_date)

  # given a date, returns combination of weekday and period
  wkday_period <- get_wkday_period(daily_seq)

  # subset of load_profiles_lst
  tmp <- load_profiles_lst[profiles]

  vals <- vector("list", length = profiles_n)
  names(vals) <- profiles

  for(profil in profiles) {
    vals[[profil]] <- tmp[[profil]][, wkday_period]
  }

  # timestamp for output
  time_seq <- get_15min_seq(start, end + 1)
  time_seq_n <- length(time_seq)

    out <-   data.frame(
      profile = rep(profiles, each = time_seq_n - 1L),
      date_time = rep(time_seq[-time_seq_n], profiles_n),
      watt = unlist(vals, use.names = FALSE)
    )

  out
}



