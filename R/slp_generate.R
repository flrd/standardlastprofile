#' Generate a Load Profile
#'
#' Generate a standard load profile in watts, normalized to an annual
#' consumption of 1,000 kWh.
#'
#' @param profile_id load profile identifier, see 'Details'.
#' @param start_date start date in ISO 8601 format, required
#' @param end_date end date in ISO 8601 format, required
#'
#' @source <https://www.bdew.de/energie/standardlastprofile-strom/>
#' @source <https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf>
#' @source <https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf>
#'
#' @details
#' Supported profiles are:
#' - `H0`: households (German: "Haushalte")
#' - `G0` to `G6`: commerce ("Gewerbe")
#' - `L0` to `L2`: agriculture ("Landwirtschaft")
#'
#' Call [slp_info()] for more information about profiles.
#'
#' The standard load profiles are differentiated according to winter,
#' transitional period, summer as well as workday, Saturday, Sunday. See:
#' <https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf>
#' for the methodology used to determine the profiles.
#'
#'Periods are defined as:
#'- `summer`: May 15 to September 14
#'- `winter`: November 1 to March 20
#'- `transition`: March 21 to May 14, and September 15 to October 31
#'
#'There are 3 different characteristic days:
#'- `saturday`: Saturdays; Dec 24th and Dec 31th are considered a Saturday too,
#'if they are not a Sunday
#'- `sunday`: Sundays and all public holidays
#'- `workday`: Monday to Friday
#'
#'**Note**: The package supports nationwide, public holidays for Germany. Those
#'were retrieved from the [nager.Date API](https://github.com/nager/Nager.Date).
#'
#' @return A data.frame with four variables:
#' - `profile_id`, character, load profile identifier
#' - `start_time`, POSIXct / POSIXlt, start time
#' - `end_time`, POSIXct / POSIXlt, end time
#' - `watts`, numeric, electric power
#'
#' @export
#' @examples
#' today <- Sys.Date()
#' L <- slp_generate(c("L0", "L1", "L2"), today, today + 1)
#' head(L)
slp_generate <- function(
    profile_id = c("H0", "G0", "G1", "G2", "G3", "G4", "G5", "G6", "L0", "L1", "L2"),
    start_date,
    end_date) {

  start <- as_date(start_date)
  end <- as_date(end_date)

  if(anyNA(c(start, end))) {
    stop("Please provide a valid date in ISO 8601 format")
  }

  if(start < as_date("1973-01-01") || end > as_date("2073-12-21")) {
    stop("Supported date range must be between 1973-01-01 and 2073-12-31.")
  }

  profile_id <- toupper(profile_id)
  profile_id <- unique(profile_id)

  profile_id <- match.arg(arg = profile_id, several.ok = TRUE)
  profiles_n <- length(profile_id)

  # returns vector of class 'Date'
  daily_seq <- get_daily_sequence(start_date, end_date)

  # given a date, returns combination of weekday and period
  wkday_period <- get_wkday_period(daily_seq)

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
    days_decimal <- format_j(daily_seq) |> as.integer()

    # multiply values for each day with
    vals[["H0"]] <- tmp_h0 * rep(dynamization_fun(days_decimal), each = dim(tmp_h0)[[1]])
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



