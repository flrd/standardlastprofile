# attach packages ---------------------------------------------------------
library(readxl)
library(data.table)
library(httr2)

# load data ---------------------------------------------------------------
# url <- "https://www.bdew.de/media/documents/Profile.zip"
# filename: "Repr„sentative Profile VDEW.xls" but that is not portable ;(
path <- system.file("extdata", "representative_profiles.xls", package = "standardlastprofile")
sheets <- readxl::excel_sheets(path)
n_sheets <- length(sheets)

# creates empty list of length = n_sheets
profiles_lst <- vector(mode = "list", length = n_sheets)
names(profiles_lst) <- sheets

# populate list
for (sheet in sheets) {
  profiles_lst[[sheet]] <- readxl::read_excel(
    sheet = sheet,
    path,
    range = "A3:J99",
    col_types = c(
      "date",
      "numeric",
      "numeric",
      "numeric",
      "numeric",
      "numeric",
      "numeric",
      "numeric",
      "numeric",
      "numeric"
    )
  )
}


# data clean-up -----------------------------------------------------------
days <- c("saturday", "sunday", "workday")
periods <- c("winter", "summer", "transition")
nms <- c("timestamp", rep(periods, each = 3))

profiles_lst <- lapply(profiles_lst, function(profile) {
  # use data.table, set profile to
  data.table::setDT(profile)

  # rename columns
  data.table::setnames(profile, c(nms[1], paste(days, nms[-1], sep = "_")))

  # remove date part from 'timestamp' column; start at 00:00
  profile[, timestamp := format(timestamp, "%H:%M")]
  profile[, timestamp := c(timestamp[.N], timestamp[-.N])]
})


# create list of matrices to be used internally ---------------------------
load_profiles_lst <- lapply(profiles_lst, function(profile) {
  as.matrix(profile, rownames = "timestamp")
})


# create .csv to be added in inst/extdata ---------------------------------
load_profiles <- lapply(profiles_lst, function(profile) {
  # reshape from wide to long format
  profile <- data.table::melt(profile, measure.vars = patterns(days), value.name = days)

  # set values in column 'type' to appropriate period, remove column 'variable'
  profile[, period := `levels<-`(variable, periods)]
  profile[, variable := NULL]
  profile

}) |>
  data.table::rbindlist(idcol = "profile") |>
  data.table::melt(
    measure.vars = c("saturday", "sunday", "workday"),
    variable.name = "day",
    value.name = "watt"
) |>
  data.table::setcolorder(c("profile", "period", "day", "timestamp", "watt"))

# save VDEW_profiles_wide to disk as CSV
fwrite(x = load_profiles,
       file = system.file("/inst/extdata", "load_profiles.csv", package = "standardlastprofile"))


# fetch public holidays in Germany from nager.Date API --------------------
get_federal_holidays <- function(year) {
  if (year < 1973L || year > 2073L) {
    stop("'API supports 'only' years between 1973 and 2073.")
  }

  year <- as.character(year)
  base_url <- "https://date.nager.at/api/v3"

  resp <- httr2::request(base_url = base_url) |>
    httr2::req_user_agent("https://github.com/flrd/standardlastprofile") |>
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
      FUN = function(x) x[["date"]],
      FUN.VALUE = character(1)
    )

  federal_holidays
}


years <- seq.int(1973, 2073)
federal_holidays_DE <- sapply(years, get_federal_holidays)

names(federal_holidays_DE) <- years

# abbreviations of the 11 profiles included in this package ---------------
profiles <- c("H0", "G0", "G1", "G2", "G3", "G4", "G5", "G6", "L0", "L1", "L2")
profiles <- factor(profiles, levels = profiles)

# german description ------------------------------------------------------
description_DE = c(
  "Haushalt",
  "Gewerbe allgemein",
  "Gewerbe werktags 8-18 Uhr",
  "Gewerbe mit starkem bis überwiegendem Verbrauch in den Abendstunde",
  "Gewerbe durchlaufend",
  "Laden/ Friseur",
  "Bäckerei mit Backstube",
  "Wochenendbetrieb",
  "Landwirtschaftsbetriebe allgemein",
  "Landwirtschaftsbetriebe mit Milchwirtschaft/ Nebenerwerbs-Tierzucht",
  "Übrige Landwirtschaftsbetriebe"
)

comment_DE <- c(
  "",
  "Gewogener Mittelwert der Profile G1-G6",
  "z.B. Büros, Arztpraxen, Werkstätten, Verwaltungseinrichtungen",
  "z.B. Sportvereine, Fitnessstudios, Abendgaststätten",
  "z.B. Kühlhäuser, Pumpen, Kläranlagen",
  "",
  "",
  "z.B. Kinos",
  "Gewogener Mittelwert der Profile L1 und L2",
  "",
  ""
)

# english description -----------------------------------------------------
description_EN = c(
  "household",
  "commerce in general",
  "commerce workday from 8am - 6pm",
  "commerce with predominant consumption in evening hours",
  "commerce continous",
  "shop / barbershop",
  "bakery with bakehouse",
  "weekend business",
  "agricultural in general",
  "agricultural with dairy farming / part-time livestock farming",
  "other agricultural businesses"
)

comment_EN <- c(
  "",
  "weighted average of profiles G1-G6",
  "e.g. offices, doctor's office, workshop, administrative facilities",
  "e.g. sports club, fitness studio, evening restaurants",
  "e.g. cold storage warehouse, pumps, sewage treatment plants",
  "",
  "",
  "e.g. movie theater",
  "weighted average of profiles L1-L2",
  "",
  ""
)

# create data.frame and store internally ----------------------------------
profile_description_DE <- data.frame(
  profile = profiles, # factor
  description = description_DE,
  comment = comment_DE
)
profile_description_EN <- data.frame(
  profile = profiles, # factor
  description = description_EN,
  comment = comment_EN
)


# store in data/ to be accessible for users -------------------------------
usethis::use_data(load_profiles, overwrite = TRUE)

# store data internally in R/sysdata.rda ----------------------------------
# see: https://r-pkgs.org/data.html#sec-data-sysdata

usethis::use_data(
  load_profiles_lst,
  federal_holidays_DE,
  profile_description_DE,
  profile_description_EN,
  internal = TRUE,
  overwrite = TRUE
)
