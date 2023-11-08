#' Generate a daily time series
#'
#' @param start_date Starting date. Required
#' @param end_date End date. Required
#'
#' @return A vector of class "Date".
#' @export
#'
#' @examples
#' today <- Sys.Date()
#' get_daily_sequence(today, today + 3)
get_daily_sequence <- function(start_date, end_date) {

  start_date <- as.Date(start_date)
  end_date <- as.Date(end_date)

  stopifnot(start_date <= end_date)

  seq.Date(from = start_date, to = end_date, by = "day")
}


