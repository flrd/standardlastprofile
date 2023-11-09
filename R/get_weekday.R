#' Map a vector of class 'Date' to day of the week to each value in 'x'
#'
#' @param x A sequence of class 'Date'
#'
#' @return A character vector; a mapping from a vector of dates to 'working_day', 'saturday', or 'sunday'
get_weekday <- function(x) {

  if(!inherits(x, "Date")) {
    stop("'x' must be an object of class 'Date'.")
  }

  # weekday as a decimal number (1–7, Monday is 1), see ?strptime
  # avoid format.Date(..., %A) because it depends on the locale
  wkday_decimal <- format.Date(x, format = "%u")

  weekday <- rep("working_day", length(x))
  weekday[wkday_decimal == "6"] <- "saturday"
  weekday[wkday_decimal == "7"] <- "sunday"


  # toDo: set all public holidays to "sunday"
  holidays <- c(
    "new_years_day" = "01-01",
    "labour_day" = "05-01",
    "german_unity_day" = "10-03",
    "christmas_day" = "12-25",
    "boxing_day" = "12-26"
    )
  christmastide <- c(
    "christmas_eve" = "12-24",
    "new_years_eve" = "12-31"
  )

  x_md <- format.Date(x, "%m-%d")

  if(!any(x_md %in% c(holidays, christmastide))) {
    return(weekday)
  }

  # set December 24th & 31st to 'saturday', iff they are not a Sunday
  # https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf
  # page 30/46

  christmastide_idx <- x_md %in% c("12-24", "12-31")

  if (any(christmastide_idx)) {
    if (all(wkday_decimal[christmastide_idx] != "7")) {
      weekday[christmastide_idx] <- "saturday"
    }
  }

  # public holidays are mapped to a Sunday
  holidays_idx <- x_md %in% holidays

  if(any(holidays_idx)) {
    weekday[holidays_idx] <- "sunday"
  }

  weekday

}
