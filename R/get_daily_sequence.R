#' Generate a Daily Sequences of class 'Date'
#'
#' @param start_date Starting date. Required
#' @param end_date End date. Required
#'
#' @return A vector of class "Date".
#' @seealso [seq.Date()] which this function wraps.
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
  return(out)
}
