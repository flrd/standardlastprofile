# data-raw/normtemperatur_dwd.R
#
# Downloads daily mean temperature data from DWD open data for 10
# representative German weather stations and computes a 366-day long-term mean
# over the WMO climate normal period 1991–2020.
#
# Each station represents a distinct German climate region:
#   Oberstdorf   (3730) — Alpenrand / Allgäu         (806 m)
#   Potsdam      (3987) — Kontinentales Binnenland    ( 81 m)
#   Hamburg      (1975) — Maritime Nordseeküste       ( 11 m)
#   Freiburg     (1443) — Oberrheingraben             (237 m)
#   Chemnitz      (853) — Erzgebirge / Mittelgebirge  (416 m)
#   Düsseldorf   (1078) — Niederrhein                 ( 37 m)
#   Erfurt       (1270) — Thüringer Becken            (316 m)
#   Frankfurt    (1420) — Rhein-Main-Gebiet           (112 m)
#   Nürnberg     (3668) — Mittelfranken               (314 m)
#   Regensburg   (4104) — Oberpfalz / Donau           (365 m)
#
# The result is a data frame `slp_gas_normtemperatur` with columns:
#   station_id  : integer DWD station ID
#   station     : character station name
#   region      : character climate region label
#   date        : Date, using the reference leap year 2020 (2020-01-01 to 2020-12-31)
#   temp_c_mean : numeric long-term mean daily temperature in °C
#
# Dates use the year 2020 (a leap year) so that Feb 29 is included. For each
# MM-DD the mean is computed across all years in 1991–2020 that have that date
# (Feb 29 averages over the 8 leap years in that period).
#
# Source: DWD Open Data, column TMK (daily mean temperature in °C)
#   https://opendata.dwd.de/climate_environment/CDC/observations_germany/
#   climate/daily/kl/

library(rdwd)

# ---- station definitions ---------------------------------------------------
stations <- data.frame(
  id = c(3730L, 3987L, 1975L, 1443L, 853L, 1078L, 1270L, 1420L, 3668L, 4104L),
  name = c(
    "Oberstdorf",
    "Potsdam",
    "Hamburg",
    "Freiburg",
    "Chemnitz",
    "Duesseldorf",
    "Erfurt",
    "Frankfurt",
    "Nuernberg",
    "Regensburg"
  ),
  region = c(
    "Alpenrand / Allgaeu",
    "Kontinentales Binnenland",
    "Maritime Nordseekueste",
    "Oberrheingraben",
    "Erzgebirge / Mittelgebirge",
    "Niederrhein",
    "Thueringer Becken",
    "Rhein-Main-Gebiet",
    "Mittelfranken",
    "Oberpfalz / Donau"
  ),
  stringsAsFactors = FALSE
)

# ---- helper: download one station (historical), return daily TMK -----------
get_tmk <- function(id, name) {
  message("Downloading: ", name, " (", id, ")")

  urls_hist <- selectDWD(id = id, res = "daily", var = "kl", per = "historical")
  files_hist <- dataDWD(urls_hist, read = FALSE, quiet = TRUE)
  raw <- readDWD(files_hist, varnames = FALSE)

  # Filter to 1991-01-01 – 2020-12-31 and keep only complete TMK records
  raw <- raw[
    format(raw$MESS_DATUM, "%Y") >= "1991" &
      format(raw$MESS_DATUM, "%Y") <= "2020" &
      !is.na(raw$TMK),
  ]

  data.frame(
    date = as.Date(raw$MESS_DATUM),
    temp_c = raw$TMK,
    stringsAsFactors = FALSE
  )
}

# ---- download all stations -------------------------------------------------
all_raw <- lapply(seq_len(nrow(stations)), function(i) {
  df <- get_tmk(stations$id[i], stations$name[i])
  df$id <- stations$id[i]
  df$name <- stations$name[i]
  df$region <- stations$region[i]
  df
})

# ---- compute 366-day long-term means ---------------------------------------
# Aggregate by month-day (MM-DD) so that:
#   - Feb 29 is averaged over the 8 leap years in 1991–2020
#   - All other days are averaged over all 30 years
# Dates from the reference leap year 2020 (2020-01-01 to 2020-12-31).

ref_dates <- seq.Date(as.Date("2020-01-01"), as.Date("2020-12-31"), by = "day")
ref_mmdd <- format(ref_dates, "%m-%d")

compute_normals <- function(df) {
  df$mmdd <- format(df$date, "%m-%d")
  agg <- aggregate(temp_c ~ mmdd, data = df, FUN = mean, na.rm = TRUE)

  result <- data.frame(
    station_id = df$id[1],
    station = df$name[1],
    region = df$region[1],
    date = ref_dates,
    temp_c_mean = NA_real_,
    stringsAsFactors = FALSE
  )
  idx <- match(ref_mmdd, agg$mmdd)
  result$temp_c_mean <- round(agg$temp_c[idx], 4)

  missing <- ref_mmdd[is.na(idx)]
  if (length(missing) > 0) {
    warning(
      df$name[1],
      ": no data for MM-DD: ",
      paste(missing, collapse = ", ")
    )
  }

  result
}

normals_list <- lapply(all_raw, compute_normals)

# ---- check completeness ---------------------------------------------------
for (i in seq_along(normals_list)) {
  n <- normals_list[[i]]
  raw <- all_raw[[i]]
  n_leap <- sum(format(raw$date, "%m-%d") == "02-29")
  n_years <- length(unique(format(raw$date, "%Y")))
  message(
    n$station[1],
    ": ",
    sum(!is.na(n$temp_c_mean)),
    "/366 days",
    " | ",
    n_years,
    " years",
    " | Feb 29 over ",
    n_leap,
    " leap years"
  )
}

slp_gas_normtemperatur <- do.call(rbind, normals_list)
rownames(slp_gas_normtemperatur) <- NULL

# ---- save to data/ (exported dataset) --------------------------------------
# slp_gas_normtemperatur is a user-facing dataset documented in R/data.R and
# accessed via the `station` argument of slp_gas_kundenwert(). use_data()
# writes data/slp_gas_normtemperatur.rda with xz compression.
usethis::use_data(slp_gas_normtemperatur, overwrite = TRUE, compress = "xz")
message(
  "Done: ",
  nrow(slp_gas_normtemperatur),
  " rows (",
  nrow(slp_gas_normtemperatur) / 366,
  " stations x 366 days)"
)
