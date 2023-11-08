
get_daily_sequence <- function(start_date = Sys.Date(), end_date = Sys.Date() + 1) {

  start_date <- as.Date(start_date)
  end_date <- as.Date(end_date)

  seq.Date(from = start_date, to = end_date, by = "day")
}

get_daily_sequence("2022-01-01", "2022-01-03")
