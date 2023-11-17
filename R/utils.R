
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

get_weekday <- function(x) {

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
  # nager.Date API covers 1972 to 2050

  yrs_rng <- format_Y(x) |> range()
  yrs_unq <- unique(yrs_rng)
  yrs_int <- as.integer(yrs_unq)

  if(length(yrs_unq) > 1L) {
    yrs_seq <- seq.int(yrs_int[1], yrs_int[2])

    holidays <- federal_holidays_DE[as.character(yrs_seq)] |>
      unlist(use.names = FALSE)
  } else {
    holidays <- federal_holidays_DE[[yrs_unq]]
  }

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

# helper to concatenate weekday and period --------------------------------

get_wkday_period <- function(x) {
  paste_snake(get_weekday(x), get_period(x))
}

# dates helpers -----------------------------------------------------------

format_u <- function(x) format.Date(x, "%u")
format_md <- function(x) format.Date(x, "%m-%d")
format_Y <- function(x) format.Date(x, "%Y")

get_15min_seq <- function(start, end) {
  seq.POSIXt(as.POSIXlt(start), as.POSIXlt(end), by = "15 min")
}


# paste string helpers ----------------------------------------------------

paste_dash <- function(...) paste(..., sep = "-")
paste_snake <- function(...) paste(..., sep = "_")
