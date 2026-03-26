# once-per-session message ------------------------------------------------

.pkg_env <- new.env(parent = emptyenv())

message_once <- \(id, ...) {
  if (isTRUE(.pkg_env[[id]])) {
    return(invisible())
  }
  .pkg_env[[id]] <- TRUE
  message(...)
}

# create a daily sequence -------------------------------------------------

get_daily_sequence <- \(start_date, end_date) {
  if (length(start_date) != 1L || length(end_date) != 1L) {
    stop("'start_date' and 'end_date' must be of length one.")
  }

  start_date <- as_date(start_date)
  end_date <- as_date(end_date)

  if (anyNA(c(start_date, end_date))) {
    stop(
      "'start_date' and 'end_date' must follow the ISO 8601 date format, i.e. '%Y-%m-%d'."
    )
  }

  if (start_date > end_date) {
    stop("'start_date' must not be later than 'end_date'.")
  }

  seq.Date(from = start_date, to = end_date, by = "day")
}

# date helpers ------------------------------------------------------------

is_date <- \(x) inherits(x, "Date")

as_date <- \(x) {
  if (is_date(x)) {
    return(x)
  }

  tryCatch(
    expr = {
      as.Date.character(x)
    },
    error = \(e) {
      # return value in case of error
      return(NA_character_)
    }
  )
}

# Holiday resolution helpers ----------------------------------------------

get_holidays <- \(x, years) {
  idx <- x[["year"]] %in% years & x[["region"]] == "DE"
  x[idx, "holiday"]
}

# Resolve the effective set of holiday dates for a Date vector x.
# - holidays NULL:  fetch nationwide built-in data for the years spanned by x
# - holidays other: use as-is (may be an empty Date vector when the caller
#   has already converted holidays = NA to as.Date(character(0L)))
resolve_holiday_dates <- \(x, holidays) {
  if (!is.null(holidays)) {
    return(holidays)
  }
  yrs_seq <- seq.int(
    as.integer(min(format_Y(x))),
    as.integer(max(format_Y(x)))
  )
  as.Date(get_holidays(x = holidays_DE, years = yrs_seq))
}

# Map a date to an electricity weekday ------------------------------------
# Returns "workday", "saturday", or "sunday".

get_weekday <- \(x, holidays = NULL) {
  if (!is_date(x)) {
    stop("'x' must be an object of class 'Date'.")
  }

  # weekday as a decimal number (1–7, Monday is 1), see ?strptime
  # avoid format.Date(..., %A) because it depends on the locale
  wkday_decimal <- format_u(x)

  weekday <- rep("workday", length(x))
  weekday[wkday_decimal == "6"] <- "saturday"
  weekday[wkday_decimal == "7"] <- "sunday"

  x_md <- format_md(x)

  holiday_dates <- resolve_holiday_dates(x, holidays)

  # public holidays are mapped to a Sunday
  weekday[x %in% holiday_dates] <- "sunday"

  # Dec 24th & Dec 31st are treated as Saturday unless already Sunday —
  # checking weekday (not wkday_decimal) captures both calendar Sundays and
  # public holidays in one condition, so no assignment is ever overridden.
  # see page 30/46 in:
  # https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf
  christmastide <- c("12-24", "12-31")
  weekday[x_md %in% christmastide & weekday != "sunday"] <- "saturday"

  weekday
}

# Map dates to gas weekday keys -------------------------------------------
# Returns a character vector of "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su".
# Public holidays and Dec 24 / Dec 31 follow the same rules as electricity:
# holidays -> "Su", Dec 24 & 31 -> "Sa" (unless already "Su").

get_gas_weekday_key <- \(x, holidays = NULL) {
  if (!is_date(x)) {
    stop("'x' must be an object of class 'Date'.")
  }

  # %u: weekday decimal 1 (Monday) to 7 (Sunday)
  wkday_decimal <- format_u(x)

  key_map <- c(
    "1" = "Mo",
    "2" = "Tu",
    "3" = "We",
    "4" = "Th",
    "5" = "Fr",
    "6" = "Sa",
    "7" = "Su"
  )
  keys <- unname(key_map[wkday_decimal])

  x_md <- format_md(x)

  holiday_dates <- resolve_holiday_dates(x, holidays)

  # public holidays -> Sunday
  keys[x %in% holiday_dates] <- "Su"

  # Dec 24 & Dec 31 -> Saturday (unless already Sunday)
  christmastide <- c("12-24", "12-31")
  keys[x_md %in% christmastide & keys != "Su"] <- "Sa"

  keys
}

# Map date to consumption period ------------------------------------------

get_period <- \(x) {
  if (!is_date(x)) {
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

  if (length(yrs_rng) == 1L) {
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
  periods <- x_bp_names[findInterval(x, x_bp)]

  periods
}


# Validate profile IDs ----------------------------------------------------

match_profile <- \(profile_id) {
  valid <- c(
    "H0",
    "G0",
    "G1",
    "G2",
    "G3",
    "G4",
    "G5",
    "G6",
    "L0",
    "L1",
    "L2",
    "H25",
    "G25",
    "L25",
    "P25",
    "S25"
  )

  if (missing(profile_id) || length(profile_id) == 0L) {
    stop("Please provide at least one value as 'profile_id'.")
  }

  profile_id <- toupper(as.character(profile_id))

  invalid <- setdiff(profile_id, valid)
  if (length(invalid) > 0L) {
    stop(
      "'profile_id' should be one of ",
      paste0("'", valid, "'", collapse = ", "),
      "."
    )
  }

  profile_id
}

match_profile_gas <- \(profile_id) {
  valid <- c(
    "HEF",
    "HMF",
    "HKO",
    "GKO",
    "GHA",
    "GMK",
    "GBD",
    "GBH",
    "GWA",
    "GGA",
    "GBA",
    "GGB",
    "GPD",
    "GMF",
    "GHD"
  )

  if (missing(profile_id) || length(profile_id) == 0L) {
    stop("Please provide at least one value as 'profile_id'.")
  }

  profile_id <- toupper(as.character(profile_id))

  invalid <- setdiff(profile_id, valid)
  if (length(invalid) > 0L) {
    stop(
      "'profile_id' should be one of ",
      paste0("'", valid, "'", collapse = ", "),
      "."
    )
  }

  profile_id
}

# Composite weekday + period/month helpers --------------------------------

get_wkday_period <- \(x, holidays = NULL) {
  paste_snake(
    get_weekday(x, holidays = holidays),
    get_period(x)
  )
}

get_wkday_month <- \(x, holidays = NULL) {
  month_name <- tolower(month.name[as.integer(format_m(x))])
  paste_snake(
    get_weekday(x, holidays = holidays),
    month_name
  )
}


# Dynamization function ---------------------------------------------------

dynamization_fun <- \(x) {
  1.24 +
    0.0021 * x +
    -0.0000702 * x^2 +
    0.00000032 * x^3 +
    -0.000000000392 * x^4
}


# Date format helpers -----------------------------------------------------

format_u <- \(x) format.Date(x, "%u") # Weekday as a decimal number (1–7, Monday is 1).
format_md <- \(x) format.Date(x, "%m-%d") # Month as decimal number - Day of the month
format_m <- \(x) format.Date(x, "%m") # Month as decimal number (01–12)
format_Y <- \(x) format.Date(x, "%Y") # Year with century
format_j <- \(x) format.Date(x, "%j") # Day of year as decimal number (001–366)

get_15min_seq <- \(start, end) {
  seq.POSIXt(as.POSIXlt(start), as.POSIXlt(end), by = "15 min")
}


# String helpers ----------------------------------------------------------

paste_dash <- \(...) paste(..., sep = "-")
paste_snake <- \(...) paste(..., sep = "_")


# Gas SLP profile parameters (SigLinDe) ------------------------------------
# Source: BDEW/VKU/GEODE. Leitfaden Abwicklung von Standardlastprofilen Gas
#   (KoV XIV.2, Stand: 30.9.2019), Anlage 6, pp. 140–163. Available at
#   <https://www.bdew.de/service/standardvertraege/kooperationsvereinbarung-gas/>
#   The underlying research was published as: BDEW/FfE (2015). Weiterentwicklung
#   des Standardlastprofilverfahrens Gas. Endbericht. Anhang 7.1, p. 24.
#   The 2019 revision (encoded in the 2025 Leitfaden document) supersedes the
#   2015 values and is the authoritative parameter source used here.
#
# Two variants (German: Ausprägungen) are provided:
#   "34" — 57 % linear component; BDEW Leitfaden 2018 default
#   "33" — 45 % linear component; alternative for some distribution network areas
#
# Distribution network operators must test individually which variant fits their grid best
# (2015 report, p. 12). The variant argument in slp_gas() selects
# between the two; the default is "34".
#
# HKO (Kochgasprofil) is a pure sigmoid profile (old Ausprägung 03) that was
# explicitly excluded from the SigLinDe linearisation. It has no 33/34 variant;
# the same parameters apply regardless of the variant argument.
#
# theta0 = 40 °C is a fixed constant for all profiles and both variants.

.gas_profile_params <- list(
  "34" = list(
    HEF = list(
      A = 1.3819663,
      B = -37.4124155,
      C = 6.1723179,
      D = 0.0396284,
      theta0 = 40,
      mH = -0.0672159,
      bH = 1.1167138,
      mW = -0.0019982,
      bW = 0.1355070
    ),
    HMF = list(
      A = 1.0443538,
      B = -35.0333754,
      C = 6.2240634,
      D = 0.0502917,
      theta0 = 40,
      mH = -0.0535830,
      bH = 0.9995901,
      mW = -0.0021758,
      bW = 0.1633299
    ),
    HKO = list(
      A = 0.4040932,
      B = -24.4392968,
      C = 6.5718175,
      D = 0.7107710,
      theta0 = 40,
      mH = 0,
      bH = 0,
      mW = 0,
      bW = 0
    ),
    GKO = list(
      A = 1.4256684,
      B = -36.6590504,
      C = 7.6083226,
      D = 0.0371116,
      theta0 = 40,
      mH = -0.0809359,
      bH = 1.2364527,
      mW = -0.0007628,
      bW = 0.1002979
    ),
    GHA = list(
      A = 1.8398455,
      B = -37.8282037,
      C = 8.1593369,
      D = 0.0259710,
      theta0 = 40,
      mH = -0.1069262,
      bH = 1.4552240,
      mW = -0.0004920,
      bW = 0.0691851
    ),
    GMK = list(
      A = 1.3284913,
      B = -35.8715062,
      C = 7.5186829,
      D = 0.0175540,
      theta0 = 40,
      mH = -0.0758983,
      bH = 1.1942555,
      mW = -0.0008980,
      bW = 0.0603337
    ),
    GBD = list(
      A = 1.5175792,
      B = -37.5000000,
      C = 6.8000000,
      D = 0.0295801,
      theta0 = 40,
      mH = -0.0788559,
      bH = 1.2161250,
      mW = -0.0013134,
      bW = 0.0968721
    ),
    GBH = list(
      A = 0.9872585,
      B = -35.2532124,
      C = 6.0587001,
      D = 0.0793512,
      theta0 = 40,
      mH = -0.0495013,
      bH = 0.9637999,
      mW = -0.0022304,
      bW = 0.2288398
    ),
    GWA = list(
      A = 0.3925339,
      B = -35.3000000,
      C = 4.8662747,
      D = 0.3045099,
      theta0 = 40,
      mH = -0.0167993,
      bH = 0.6710889,
      mW = -0.0020301,
      bW = 0.5614623
    ),
    GGA = list(
      A = 1.1848320,
      B = -36.0000000,
      C = 7.7368518,
      D = 0.0793107,
      theta0 = 40,
      mH = -0.0687383,
      bH = 1.1308570,
      mW = -0.0006587,
      bW = 0.1910301
    ),
    GBA = list(
      A = 0.3537640,
      B = -33.3500000,
      C = 5.7212303,
      D = 0.3033305,
      theta0 = 40,
      mH = -0.0177463,
      bH = 0.6825699,
      mW = -0.0013912,
      bW = 0.5434624
    ),
    GGB = list(
      A = 1.6266812,
      B = -37.8825368,
      C = 6.9836070,
      D = 0.0297136,
      theta0 = 40,
      mH = -0.0854333,
      bH = 1.2709629,
      mW = -0.0011319,
      bW = 0.0928124
    ),
    GPD = list(
      A = 1.8834609,
      B = -37.0000000,
      C = 10.2405021,
      D = 0.0275470,
      theta0 = 40,
      mH = -0.1253100,
      bH = 1.6275999,
      mW = -0.0001105,
      bW = 0.0635119
    ),
    GMF = list(
      A = 1.0443538,
      B = -35.0333754,
      C = 6.2240634,
      D = 0.0502917,
      theta0 = 40,
      mH = -0.0535830,
      bH = 0.9995901,
      mW = -0.0021758,
      bW = 0.1633299
    ),
    GHD = list(
      A = 1.2569600,
      B = -36.6078453,
      C = 7.3211870,
      D = 0.0776960,
      theta0 = 40,
      mH = -0.0696826,
      bH = 1.1379702,
      mW = -0.0008522,
      bW = 0.1921068
    )
  ),
  "33" = list(
    HEF = list(
      A = 1.6209544,
      B = -37.1833141,
      C = 5.6727847,
      D = 0.0716431,
      theta0 = 40,
      mH = -0.0495700,
      bH = 0.8401015,
      mW = -0.0022090,
      bW = 0.1074468
    ),
    HMF = list(
      A = 1.2328655,
      B = -34.7213605,
      C = 5.8164304,
      D = 0.0873352,
      theta0 = 40,
      mH = -0.0409284,
      bH = 0.7672920,
      mW = -0.0022320,
      bW = 0.1199207
    ),
    HKO = list(
      A = 0.4040932,
      B = -24.4392968,
      C = 6.5718175,
      D = 0.7107710,
      theta0 = 40,
      mH = 0,
      bH = 0,
      mW = 0,
      bW = 0
    ),
    GKO = list(
      A = 1.3554515,
      B = -35.1412563,
      C = 7.1303395,
      D = 0.0990619,
      theta0 = 40,
      mH = -0.0526487,
      bH = 0.8626086,
      mW = -0.0008808,
      bW = 0.0964014
    ),
    GHA = list(
      A = 1.9724775,
      B = -36.9650065,
      C = 7.2256947,
      D = 0.0345782,
      theta0 = 40,
      mH = -0.0742174,
      bH = 1.0448869,
      mW = -0.0008295,
      bW = 0.0461795
    ),
    GMK = list(
      A = 1.4202419,
      B = -34.8806130,
      C = 6.5951899,
      D = 0.0385317,
      theta0 = 40,
      mH = -0.0521084,
      bH = 0.8647919,
      mW = -0.0014369,
      bW = 0.0637602
    ),
    GBD = list(
      A = 1.4633682,
      B = -36.1794117,
      C = 5.9265162,
      D = 0.0808835,
      theta0 = 40,
      mH = -0.0475800,
      bH = 0.8230754,
      mW = -0.0019273,
      bW = 0.1077046
    ),
    GBH = list(
      A = 0.9874283,
      B = -35.2532124,
      C = 6.1544406,
      D = 0.2265716,
      theta0 = 40,
      mH = -0.0339020,
      bH = 0.6938234,
      mW = -0.0012849,
      bW = 0.2029732
    ),
    GWA = list(
      A = 0.3337838,
      B = -36.0237912,
      C = 4.8662747,
      D = 0.4912280,
      theta0 = 40,
      mH = -0.0092263,
      bH = 0.4595757,
      mW = -0.0009676,
      bW = 0.3964291
    ),
    GGA = list(
      A = 1.1582082,
      B = -36.2878584,
      C = 6.5885126,
      D = 0.2235680,
      theta0 = 40,
      mH = -0.0410335,
      bH = 0.7526451,
      mW = -0.0009088,
      bW = 0.1916641
    ),
    GBA = list(
      A = 0.2770087,
      B = -33.0000000,
      C = 5.7212303,
      D = 0.4865118,
      theta0 = 40,
      mH = -0.0094849,
      bH = 0.4630237,
      mW = -0.0007134,
      bW = 0.3867447
    ),
    GGB = list(
      A = 1.8213778,
      B = -37.5000000,
      C = 6.3462148,
      D = 0.0678118,
      theta0 = 40,
      mH = -0.0607666,
      bH = 0.9308159,
      mW = -0.0013967,
      bW = 0.0850399
    ),
    GPD = list(
      A = 1.7110739,
      B = -35.8000000,
      C = 8.4000000,
      D = 0.0702546,
      theta0 = 40,
      mH = -0.0745381,
      bH = 1.0463005,
      mW = -0.0003672,
      bW = 0.0621882
    ),
    GMF = list(
      A = 1.2328655,
      B = -34.7213605,
      C = 5.8164304,
      D = 0.0873352,
      theta0 = 40,
      mH = -0.0409284,
      bH = 0.7672920,
      mW = -0.0022320,
      bW = 0.1199207
    ),
    GHD = list(
      A = 1.3010623,
      B = -35.6816144,
      C = 6.6857976,
      D = 0.1409267,
      theta0 = 40,
      mH = -0.0473428,
      bH = 0.8141691,
      mW = -0.0010601,
      bW = 0.1325092
    )
  )
)


# Gas SLP weekday factors --------------------------------------------------
# Source: BDEW/VKU/GEODE Leitfaden 2018, Anlage 6, pp. 140–163
#         (per-profile data sheets; one F_WT table per profile)
# Keys: Mo = Monday, Tu = Tuesday, We = Wednesday, Th = Thursday,
#       Fr = Friday, Sa = Saturday, Su = Sunday

.gas_weekday_factors <- list(
  HEF = c(Mo = 1, Tu = 1, We = 1, Th = 1, Fr = 1, Sa = 1, Su = 1),
  HMF = c(Mo = 1, Tu = 1, We = 1, Th = 1, Fr = 1, Sa = 1, Su = 1),
  HKO = c(Mo = 1, Tu = 1, We = 1, Th = 1, Fr = 1, Sa = 1, Su = 1),
  GKO = c(
    Mo = 1.0354,
    Tu = 1.0523,
    We = 1.0449,
    Th = 1.0494,
    Fr = 0.9885,
    Sa = 0.8860,
    Su = 0.9435
  ),
  GHA = c(
    Mo = 1.0358,
    Tu = 1.0232,
    We = 1.0252,
    Th = 1.0295,
    Fr = 1.0253,
    Sa = 0.9675,
    Su = 0.8935
  ),
  GMK = c(
    Mo = 1.0699,
    Tu = 1.0365,
    We = 0.9933,
    Th = 0.9948,
    Fr = 1.0659,
    Sa = 0.9362,
    Su = 0.9034
  ),
  GBD = c(
    Mo = 1.1052,
    Tu = 1.0857,
    We = 1.0378,
    Th = 1.0622,
    Fr = 1.0266,
    Sa = 0.7629,
    Su = 0.9196
  ),
  GBH = c(
    Mo = 0.9767,
    Tu = 1.0389,
    We = 1.0028,
    Th = 1.0162,
    Fr = 1.0024,
    Sa = 1.0043,
    Su = 0.9587
  ),
  GWA = c(
    Mo = 1.2457,
    Tu = 1.2615,
    We = 1.2707,
    Th = 1.2430,
    Fr = 1.1276,
    Sa = 0.3877,
    Su = 0.4638
  ),
  GGA = c(
    Mo = 0.9322,
    Tu = 0.9894,
    We = 1.0033,
    Th = 1.0109,
    Fr = 1.0180,
    Sa = 1.0356,
    Su = 1.0106
  ),
  GBA = c(
    Mo = 1.0848,
    Tu = 1.1211,
    We = 1.0769,
    Th = 1.1353,
    Fr = 1.1402,
    Sa = 0.4852,
    Su = 0.9565
  ),
  GGB = c(
    Mo = 0.9897,
    Tu = 0.9627,
    We = 1.0507,
    Th = 1.0552,
    Fr = 1.0297,
    Sa = 0.9767,
    Su = 0.9353
  ),
  GPD = c(
    Mo = 1.0214,
    Tu = 1.0866,
    We = 1.0720,
    Th = 1.0557,
    Fr = 1.0117,
    Sa = 0.9001,
    Su = 0.8525
  ),
  GMF = c(
    Mo = 1.0354,
    Tu = 1.0523,
    We = 1.0449,
    Th = 1.0494,
    Fr = 0.9885,
    Sa = 0.8860,
    Su = 0.9435
  ),
  GHD = c(
    Mo = 1.0300,
    Tu = 1.0300,
    We = 1.0200,
    Th = 1.0300,
    Fr = 1.0100,
    Sa = 0.9300,
    Su = 0.9500
  )
)
