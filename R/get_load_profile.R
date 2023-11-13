get_load_profile <- function(
    profile = c("H0", "G0", "G1", "G2", "G3", "G4", "G5", "G6", "L0", "L1", "L2"),
    start_date = Sys.Date(),
    end_date = Sys.Date() + 2) {

  profile <- toupper(profile)
  profile <- match.arg(arg = profile)

  daily_seq <- get_daily_sequence(start_date, end_date)
  wkday_period <- get_wkday_period(daily_seq)

  tmp <- load_profiles_lst[[profile]][, wkday_period]

  n_rows <- dim(tmp)[[1]]
  #
  # date_rng <- rep(tmp_dates[["request_period"]], each = n_rows)
  # time_rng <- dimnames(tmp_values)[[1]]
  #
  #
  #
  # out <- data.frame(
  #   start_time = make_utc(date_rng, c(time_rng[n_rows], time_rng[-n_rows])),
  #   # end_time = make_utc(date_rng, time_rng),
  #   values = tmp_values |> as.vector()
  # )
  #
  tmp

}



