#' Map a sequence of dates to a consumption period
#'
#' @param x A vector of class 'Date'
#'
#' @return A character vector, a vector of dates mapped to 'summer', 'winter', or 'transition'
get_period <- function(x) {

  if(!is_date(x)) {
    stop("'x' must be an object of class 'Date'.")
  }

  # range(x) returns first and last values of 'x'
  yrs_rng <- range(x) |>
    unique() |>
    format.Date("%Y") |>
    as.integer()

  # extending 'yrs_rng' by +-1 year on each side to ensure
  # findInterval(.., time_series_bp) will return a vector in
  # which each value is >= 1, i.e. we ensure that
  # 'time_series_bp' starts before 'time_series' does

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
  x_bp_names <- bp[format.Date(x_bp, "%m-%d")] |>
    unname()

  # magic, see: https://stackoverflow.com/a/64666688
  periods <- x_bp_names[ findInterval(x, x_bp) ]

  return(periods)

}

get_wkday_period <- function(x) {
  paste_snake(get_weekday(x), get_period(x))
}

paste_dash <- function(...) paste(..., sep = "-")
paste_snake <- function(...) paste(..., sep = "_")
