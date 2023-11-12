#' Map a vector of class 'Date' to 'working_day', 'saturday', or 'sunday'
#'
#' @param x A sequence of class 'Date'
#'
#' @return A character vector; a vector of dates mapped to 'working_day', 'saturday', or 'sunday'
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

  # call nager.Date API to get public holidays in Germany
  # for all years in 'x'

  yrs_rng <- format.Date(x, "%Y") |> range()
  yrs_unq <- unique(yrs_rng)

  if(length(yrs_unq) == 1L) {
    holidays <- federal_holidays(yrs_unq)
  } else {
    yrs_int <- as.integer(yrs_unq)
    holidays <- as.Date(sapply(seq.int(yrs_int[1], yrs_int[2]), federal_holidays))
  }

  # public holidays are mapped to a Sunday

  holidays_idx <- x %in% holidays

  if(any(holidays_idx)) {
    weekday[holidays_idx] <- "sunday"
  }

  weekday

}

format_md <- function(x) format.Date(x, "%m-%d")


# get public holidays from nager.Date API ---------------------------------

federal_holidays <- function(year) {
  if (year < 1973L || year > 2073L) {
    stop("'API supports years between 1973 and 2073.")
  }

  year <- as.character(year)
  base_url <- "https://date.nager.at/api/v3"

  resp <- httr2::request(base_url = base_url) |>
    httr2::req_user_agent("https://github.com/flrd/standardlastprofil") |>
    httr2::req_url_path_append("PublicHolidays") |>
    httr2::req_url_path_append(year) |>
    httr2::req_url_path_append("DE") |>
    httr2::req_perform()

  resp_body <- resp |>
    httr2::resp_body_json()

  # we'll only support nationwide holidays
  is_federal <- function(x)
    is.null(x[["counties"]])

  federal_idx <- vapply(resp_body, is_federal, logical(1))
  federal_holidays <-
    vapply(
      resp_body[federal_idx],
      FUN.VALUE = character(1),
      FUN = function(x) {
        x[["date"]]
      }
    )

  federal_holidays
}
