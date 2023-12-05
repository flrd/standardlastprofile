
# create a daily sequence -------------------------------------------------

get_daily_sequence <- function(start_date, end_date) {

  if (length(start_date) != 1L || length(end_date) != 1L) {
    stop("'start_date and 'end_date' must be of length one.")
  }

  start_date <- as_date(start_date)
  end_date <- as_date(end_date)

  if (anyNA(c(start_date, end_date))) {
    stop("'start_date and 'end_date' must follow the ISO 8601 date format, i.e. '%Y-%m-%d'.")
  }

  stopifnot(start_date <= end_date)

  seq.Date(from = start_date, to = end_date, by = "day")
}

# date helpers ------------------------------------------------------------

is_date <- function(x) {
  inherits(x, "Date")
}

as_date <- function(x) {

  if (is_date(x)) {
    return(x)
  }

  out <- tryCatch(
    expr = {
      as.Date.character(x)
    },
    error = function(e) {
      # return value in case of error
      return(NA_character_)
    }
  )
  out
}

# Map a date to a weekday -------------------------------------------------

get_holidays <- function(x, years, state_code) {

  state_code <- paste_dash("DE", state_code)

  idx <- x[["year"]] %in% years & x[["region"]] %in% c("DE", state_code)
  x[idx, "holiday"]
}

get_weekday <- function(x, state_code = NULL) {

  if(!is_date(x)) {
    stop("'x' must be an object of class 'Date'.")
  }

  # weekday as a decimal number (1–7, Monday is 1), see ?strptime
  # avoid format.Date(..., %A) because it depends on the locale

  wkday_decimal <- format_u(x)

  weekday <- rep("workday", length(x))
  weekday[wkday_decimal == "6"] <- "saturday"
  weekday[wkday_decimal == "7"] <- "sunday"

  x_md <- format_md(x)

  # set December 24th & 31st to 'saturday', iff they are not a Sunday
  # see page 30/46 in:
  # https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf

  christmastide <- c(
    "christmas_eve" = "12-24",
    "new_years_eve" = "12-31"
  )

  christmastide_idx <- x_md %in% christmastide

  if (any(christmastide_idx)) {
    if (all(wkday_decimal[christmastide_idx] != "7")) {
      weekday[christmastide_idx] <- "saturday"
    }
  }

  # get public holidays in Germany for all years in 'x'

  # range returns a vector of length 2
  yrs_rng <- range(format_Y(x))
  yrs_int <- as.integer(yrs_rng)
  yrs_seq <- seq.int(yrs_int[1], yrs_int[2])

  holidays <- get_holidays(
    x = holidays_DE,
    years = yrs_seq,
    state_code = state_code
    )

  # public holidays are mapped to a Sunday
  holidays_idx <- x %in% as.Date(holidays)

  if(any(holidays_idx)) {
    weekday[holidays_idx] <- "sunday"
  }

  weekday

}

# Map date to consumption period ------------------------------------------

get_period <- function(x) {

  if(!is_date(x)) {
    stop("'x' must be an object of class 'Date'.")
  }

  # range(x) returns first and last values of 'x'
  yrs_rng <- range(x) |>
    unique() |>
    format_Y() |>
    as.integer()

  # extending 'yrs_rng' by +-1 year on each side to ensure
  # findInterval(.., x_bp) will return a vector in
  # which each value is >= 1, i.e. we ensure that
  # 'x_bp' starts before 'time_series' does

  if(length(yrs_rng) == 1L) {
    yrs_rng_extended <- yrs_rng + seq.int(-1, 1)
  } else {
    yrs_rng_extended <- seq.int(yrs_rng[1] - 1L, yrs_rng[2] + 1L)
  }

  # define periods according to the BDEW, see page: 4 (5/34):
  # https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf
  #
  # winter: November 1 - March 20
  # summer: May 15 - September 14
  # transition: March 21 - May 14; September 15 - October 31

  # the reason this vector is defined with the dates of breaks
  # points ('bp') as names and not the other way around is the
  # Extract function (`[`) used below in:
  # bp[format.Date(x_bp, "-%m-%d")], see ?Extract

  bp <- c(
    "03-21" = "transition",
    "05-15" = "summer",
    "09-15" = "transition",
    "11-01" = "winter"
  )

  # creates a vector of break points covering the years
  # defined in 'yrs_rng_extended'
  tmp <- expand.grid(yrs_rng_extended, names(bp))
  x_bp <- do.call(paste_dash, tmp) |>
    as.Date() |>
    sort()

  # create a vector of length: length(x_bp) which maps name of
  # each break point to the respective value in 'bp', i.e.
  # the name of the period
  x_bp_names <- bp[format_md(x_bp)] |>
    unname()

  # magic, see: https://stackoverflow.com/a/64666688
  periods <- x_bp_names[ findInterval(x, x_bp) ]

  periods

}


# check for valid profile_id ----------------------------------------------

# helper to check if profile_id is valid
match_profile <- function(profile_id) {

  if(missing(profile_id)) {
    stop("Please provide at least one value as 'profile_id'.")
  }

  profile_id <- toupper(profile_id)
  profile_id <- unique(profile_id)

  out <- tryCatch(
    expr = {
      match.arg(arg = profile_id,
                choices = c("H0", "G0", "G1", "G2", "G3", "G4", "G5", "G6", "L0", "L1", "L2"),
                several.ok = TRUE)
    },
    error = function(e) {
      # return value in case of error
      return(NA_character_)
    }
  )

  if(anyNA(out)) {
    stop("'profile_id' should be one of 'H0', 'G0', 'G1', 'G2', 'G3', 'G4', 'G5', 'G6', 'L0', 'L1', 'L2'.")
  }

  out

}

# helper to concatenate weekday and period --------------------------------

# This function adds "DE-" as prefixe to state codes if a user did not provide it,
# see also: [ISO 3166-2:DE](https://en.wikipedia.org/wiki/ISO_3166-2:DE)
standardise_state_names <- function(state) {

  tmp <- c("DE-BW", "DE-BY", "DE-ST", "DE-BE", "DE-MV", "DE-SL", "DE-RP", "DE-NW", "DE-HE", "DE-SH", "DE-NI", "DE-BB", "DE-HH", "DE-HB", "DE-SN", "DE-TH")
  state <- match.arg(
    state,
    sub("DE-", "", tmp))
  paste_dash("DE", state)
}

get_wkday_period <- function(x, state_code = NULL) {
  paste_snake(get_weekday(x, state_code = state_code), get_period(x))
}


# dynamization function ---------------------------------------------------

dynamization_fun <- function(x) {
  1.24 + 0.0021*x + -0.0000702*x^2 + 0.00000032*x^3 + -0.000000000392*x^4
}


# dates helpers -----------------------------------------------------------

format_u <- function(x) format.Date(x, "%u")      # Weekday as a decimal number (1–7, Monday is 1).
format_md <- function(x) format.Date(x, "%m-%d")  # Month as decimal number - Day of the month
format_Y <- function(x) format.Date(x, "%Y")      # Year with century
format_j <- function(x) format.Date(x, "%j")      # Day of year as decimal number (001–366)

get_15min_seq <- function(start, end) {
  seq.POSIXt(as.POSIXlt(start), as.POSIXlt(end), by = "15 min")
}


# paste string helpers ----------------------------------------------------

paste_dash <- function(...) paste(..., sep = "-")
paste_snake <- function(...) paste(..., sep = "_")
