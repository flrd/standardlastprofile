# attach packages ---------------------------------------------------------
library(readxl)
library(data.table)
library(httr2)


# 1. Helper function for cleaning and matrix conversion -------------------
process_slp_sheet <- \(
  path,
  sheet,
  range,
  col_names,
  watt_multiplier = 1
) {
  dt <- as.data.table(read_excel(path, sheet = sheet, range = range))

  # Set names
  setnames(dt, c("timestamp", col_names))

  # Clean timestamp
  if (inherits(dt$timestamp, "POSIXt")) {
    # 1999 Data: shift so 00:00 is first
    dt[, timestamp := format(timestamp, "%H:%M")]
    dt[, timestamp := c(timestamp[.N], timestamp[-.N])]
  } else {
    # 2025 Data: Remove time after dash from "00:00-00:15" strings
    dt[, timestamp := sub("-.*", "", timestamp)]
  }

  # Convert to matrix and scale
  mat <- as.matrix(dt[, -1], rownames = dt$timestamp)
  return(mat * watt_multiplier)
}


# 2. Define Metadata ------------------------------------------------------
path_1999 <- "inst/extdata/BDEW_H0_G0_G1_G2_G3_G4_G5_G6_L0_L1_L2.xls"
path_2025 <- "inst/extdata/BDEW_H25_G25_L25_P25_S25.xlsx"

days <- c("saturday", "sunday", "workday")

# 1999: 9 columns — {day}_{period}
periods_1999 <- c("winter", "summer", "transition")
cols_1999 <- paste(days, rep(periods_1999, each = 3), sep = "_")

# 2025: 36 columns — {day}_{month}
# expand.grid varies first argument fastest: saturday/sunday/workday cycle
# within each month, matching SA/FT/WT order in the Excel sheets
cols_2025 <- do.call(
  paste,
  c(expand.grid(days, tolower(month.name)), sep = "_")
)


# 3. Import 1999 Data -----------------------------------------------------
sheets_1999 <- excel_sheets(path_1999)
load_profiles_1999 <- lapply(sheets_1999, \(sheet) {
  process_slp_sheet(path_1999, sheet, "A3:J99", cols_1999)
})
names(load_profiles_1999) <- sheets_1999


# 4. Import 2025 Data -----------------------------------------------------
# Values in the Excel are in kWh per 15-min interval, normalised to
# 1,000,000 kWh/a. Multiplying by 4 converts to W normalised to 1,000 kWh/a:
#   kWh / 0.25 h = 4 kW = 4,000 W; 4,000 W / 1,000 = 4 W per 1 kWh/a unit.
sheets_2025 <- c("H25", "G25", "L25", "P25", "S25")
load_profiles_2025 <- lapply(sheets_2025, \(sheet) {
  process_slp_sheet(
    path_2025,
    sheet,
    "B4:AL100",
    cols_2025,
    watt_multiplier = 4
  )
})
names(load_profiles_2025) <- sheets_2025


# 5. Combine load_profiles_lst --------------------------------------------
load_profiles_lst <- c(load_profiles_1999, load_profiles_2025)


# 6. Create tidy slp dataset ----------------------------------------------

# helper: matrix → long data.table with period column
mat_to_slp <- \(mat, period_levels) {
  dt <- as.data.table(mat, keep.rownames = "timestamp")
  dt <- melt(
    dt,
    measure.vars = patterns(days),
    value.name = days,
    variable.factor = TRUE
  )
  dt[, period := `levels<-`(variable, period_levels)]
  dt[, period := as.character(period)]
  dt[, variable := NULL]
  dt
}

slp_1999 <- lapply(
  load_profiles_1999,
  mat_to_slp,
  period_levels = periods_1999
) |>
  rbindlist(idcol = "profile_id") |>
  melt(
    measure.vars = days,
    variable.name = "day",
    variable.factor = FALSE,
    value.name = "watts"
  ) |>
  setcolorder(c("profile_id", "period", "day", "timestamp", "watts")) |>
  as.data.frame()

slp_2025 <- lapply(
  load_profiles_2025,
  mat_to_slp,
  period_levels = tolower(month.name)
) |>
  rbindlist(idcol = "profile_id") |>
  melt(
    measure.vars = days,
    variable.name = "day",
    variable.factor = FALSE,
    value.name = "watts"
  ) |>
  setcolorder(c("profile_id", "period", "day", "timestamp", "watts")) |>
  as.data.frame()

slp <- rbind(slp_1999, slp_2025)


# fetch public holidays in Germany from nager.Date API --------------------

# extract nationwide holidays
is_nationwide <- \(x) x[["global"]]

get_holidays_DE <- \(year) {
  if (year < 1990L || year > 2073L) {
    stop("'API supports 'only' years from 1990 to 2073.")
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

  idx_nation <- vapply(resp_body, is_nationwide, logical(1))
  holidays_nationwide <- data.frame(
    region = "DE",
    holiday = vapply(
      resp_body[idx_nation],
      FUN = \(x) x[["date"]],
      FUN.VALUE = character(1)
    )
  )

  holidays_states <- lapply(resp_body[!idx_nation], \(x) {
    data.frame(
      holiday = x[["date"]],
      region = unlist(x["counties"], use.names = FALSE)
    )
  }) |>
    do.call(rbind, args = _)

  out <- rbind(holidays_nationwide, holidays_states)
  cbind(data.frame(year = year), out)
}

years <- seq.int(1990, 2073)
holidays_DE <- lapply(years, get_holidays_DE) |>
  do.call(rbind, args = _)


# profile descriptions ----------------------------------------------------
profiles_1999 <- c(
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
  "L2"
)
profiles_2025 <- c("H25", "G25", "L25", "P25", "S25")
profiles <- c(profiles_1999, profiles_2025)

# German descriptions
description_DE <- c(
  H0 = "Haushalt",
  G0 = "Gewerbe allgemein",
  G1 = "Gewerbe werktags 8-18 Uhr",
  G2 = "Gewerbe mit starkem bis überwiegendem Verbrauch in den Abendstunden",
  G3 = "Gewerbe durchlaufend",
  G4 = "Laden/ Friseur",
  G5 = "Bäckerei mit Backstube",
  G6 = "Wochenendbetrieb",
  L0 = "Landwirtschaftsbetriebe allgemein",
  L1 = "Landwirtschaftsbetriebe mit Milchwirtschaft/ Nebenerwerbs-Tierzucht",
  L2 = "Übrige Landwirtschaftsbetriebe",
  H25 = "Haushalt (2025)",
  G25 = "Gewerbe allgemein (2025)",
  L25 = "Landwirtschaftsbetriebe (2025)",
  P25 = "Kombinationsprofil PV (2025)",
  S25 = "Kombinationsprofil Speicher- und PV (2025)"
)

details_DE <- c(
  H0 = "In dieses Profil werden alle Haushalte mit ausschließlichem und überwiegendem Privatverbrauch eingeordnet. Haushalte mit überwiegend privatem elektrischen Verbrauch, d.h. auch mit geringfügigem gewerblichen Bedarf sind z.B. Handelsvertreter, Heimarbeiter u.ä. mit Büro im Haushalt. Das Profil Haushalt ist nicht anwendbar bei Sonderanwendungen wie z.B. elektrischen Speicherheizungen oder Wärmepumpen.",
  G0 = "Ist eine Zuordnung zu einem der Gewerbeprofile G1 bis G6 nicht möglich oder gewollt, stellt dieses Profil den gewichteten Mittelwert der Gesamtgruppe dar.",
  G1 = "Dieses Profil repräsentiert Abnahmestellen, die typischerweise einen Verbrauch zwischen etwa 8 und 18 Uhr an den Werktagen, und keinen oder einen allenfalls geringen Verbrauch an den Wochenenden erwarten lassen (sonst siehe G4). Hierzu gehören u.a. Büros, Arzt- und Rechtsanwalts-Praxen, Werkstätten, Druckereien, Schulen, Kindergärten und Tagesstätten, Verwaltungseinrichtungen, Bankfilialen.",
  G2 = "In diesem Profil findet sich vor allem beleuchtungsorientierter Stromverbrauch. Solche Betriebe sind gekennzeichnet durch einen an den Werktagen (vor allem in der dunklen Jahreszeit) eher untergeordneten Tagesbedarf und einem in den Abendstunden liegenden Verbrauchsschwerpunkt. Hierzu gehören z.B. Tankstellen und Geschäfte mit erheblicher Schaufensterfläche. In dieses Profil sind auch Abendgaststätten und Freizeiteinrichtungen einzuordnen, soweit ihr Verbrauchsschwerpunkt nicht am Wochenende liegt, z.B. Fitneß- und Sonnenstudios, Jugendzentren (vgl. auch G6).",
  G3 = "Hier finden sich Verbrauchsstellen, die das ganze Jahr und auch im Wochenverlauf einen relativ gleichmäßigen Verbrauch mit einem spürbaren durchlaufenden Sockel haben. Beispiele sind Kläranlagen, Trinkwasser-Pumpen, Gemeinschaftsanlagen in Wohnanlagen, Kühlhäuser, Läden mit erheblichem Bedarf an Kühlung, Anlagen mit Zwangsbelüftung (z.B. Parkhäuser).",
  G4 = "Dies sind Verbrauchsstellen, die fast ausschließlich von den Ladenöffnungszeiten (Werktag bis abends und auch am Samstag bis nachmittags) bestimmt sind. Dies ist das typische Profil für Läden aller Art. Ein ähnliches Profil weisen Friseurbetriebe auf. Unterschiede durch z.B. einzelne Nachmittage ohne Geschäftsbetrieb fallen bezogen auf die Gesamtgruppe kaum ins Gewicht. Die teilweise bis 20 Uhr verlängerten Ladenöffnungszeiten haben ebenso nur geringen Einfluß, da sich die Effekte des Geschäftsbetriebs mit denen der abendlichen Ladenbeleuchtung vermischen.",
  G5 = "Bäckereien mit Backstube haben den Schwerpunkt ihres Verbrauchs an den Werktagen traditionell ab ca. 3 Uhr früh und in der Nacht zum Samstag ab etwa Mitternacht. Der Tagverbrauch ist zum Gesamtbedarf relativ gering und wird hauptsächlich von der Verkaufstätigkeit bestimmt. Verkaufsorientierte Bäckereien, in denen zu Geschäftszeiten Backwaren zubereitet werden ('Backen im Laden'), verhalten sich wie andere Läden und sind im Profil G4 einzuordnen.",
  G6 = "Betriebe mit deutlichen Verbrauchsschwerpunkt an den Wochenenden. Das sind insbesondere alle durch die Freizeitaktivitäten der Bevölkerung geprägten Geschäfte: Jugendclubs, Ausflugs- und Speisegaststätten, Tankstellen mit Waschanlagen, Kinos mit Verzehr, Sport- und Freizeiteinrichtungen.",
  L0 = "Erfolgt keine Unterscheidung der Landwirtschaftsbetriebe nach L1 oder L2 und kann keine Einordnung in eines der charakteristischen Gewerbe-Profile erfolgen, so kann mit guter Näherung dieses Profil verwendet werden. Es stellt den gewichteten Mittelwert der Gesamtgruppe für landwirtschaftliche Betriebe nach der repräsentativ für das Versorgungsgebiet der RWE Energie AG im Jahr 1992 gezogenen Stichprobe dar.",
  L1 = "Der Stromverbrauch von Milchviehbetrieben ist geprägt durch das zweimalige Melken und das anschließende Herunterkühlen der Milch. Ähnliches Verhalten zeigen Nebenerwerbsbetriebe mit z.B. Schweineaufzucht: Hier wird am frühen Morgen und am Abend (vor bzw. nach dem Haupterwerb) durch die Fütterungsvorgänge Stromverbrauch ausgelöst. Bei großen Haupterwerbsbetrieben mit Tierzucht verteilen sich solche Vorgänge auf die klassischen Arbeitsstunden, so daß das passende Gewerbe-Profil zu wählen ist.",
  L2 = "Traditionell findet sich bei den meisten westdeutschen Betrieben ein Nebeneinander von Haushalt und Produktion. Für solche Betriebe ist dieses mittlere Profil anzuwenden. Soweit in einem landwirtschaftlichen Betrieb eine weitgehend tageszeitenunabhängige Produktion vorliegt (z.B. Tierproduktionsanlagen in Ostdeutschland), ist das passende Gewerbe-Profil zu wählen.",
  H25 = "Repräsentatives Haushaltsprofil der BDEW-Veröffentlichung von 2025, normiert auf 1.000 kWh Jahresverbrauch. Das Profil löst H0 als aktualisiertes Standardlastprofil für Haushaltskunden ab.",
  G25 = "Repräsentatives Gewerbeprofil der BDEW-Veröffentlichung von 2025, normiert auf 1.000 kWh Jahresverbrauch. Das Profil löst G0 als allgemeines Gewerbe-Standardlastprofil ab.",
  L25 = "Repräsentatives Landwirtschaftsprofil der BDEW-Veröffentlichung von 2025, normiert auf 1.000 kWh Jahresverbrauch. Das Profil löst L0 als allgemeines Landwirtschafts-Standardlastprofil ab.",
  P25 = "Kombinationsprofil für Anlagen mit Photovoltaik (PV) aus der BDEW-Veröffentlichung von 2025, normiert auf 1.000 kWh Jahresverbrauch. Bildet das typische Lastverhalten von Haushalten mit PV-Anlage ab.",
  S25 = "Kombinationsprofil für Anlagen mit Speicher und Photovoltaik (PV) aus der BDEW-Veröffentlichung von 2025, normiert auf 1.000 kWh Jahresverbrauch. Bildet das typische Lastverhalten von Haushalten mit PV-Anlage und Batteriespeicher ab."
)

# English descriptions
description_EN <- c(
  H0 = "household",
  G0 = "commerce in general",
  G1 = "commerce workday from 8am - 6pm",
  G2 = "commerce with strong to predominant consumption in evening hours",
  G3 = "commerce continuous",
  G4 = "shop / hair salon",
  G5 = "bakery with bakehouse",
  G6 = "weekend business",
  L0 = "agriculture in general",
  L1 = "agriculture with dairy farming / part-time livestock farming",
  L2 = "other agricultural businesses",
  H25 = "household (2025)",
  G25 = "commerce in general (2025)",
  L25 = "agricultural (2025)",
  P25 = "combination profile PV (2025)",
  S25 = "combination profile storage and PV (2025)"
)

details_EN <- c(
  H0 = "This profile includes all households with exclusively and predominantly private consumption. Households with predominantly private electrical consumption, i.e. also with minor commercial consumption are e.g. sales representatives, home workers, etc. with an office in the household. The Household profile is not applicable for special applications such as storage heaters or heat pumps.",
  G0 = "If an assignment to one of the profiles G1 to G6 is not possible or desired, this profile represents the weighted average of the overall group.",
  G1 = "This profile represents consumers that typically use electricity between around 8 a.m. and 6 p.m. on weekdays, with little or no consumption on weekends (otherwise see G4). These include offices, doctors' offices, law firms, workshops, print shops, schools, kindergartens and daycare centres, administrative facilities and branch banks.",
  G2 = "This profile mainly includes illumination-intensive electricity consumption. Such businesses are characterised by a rather subordinate daily demand on working days (especially in the winter season) and a consumption focus in the evening hours. These include, for example, petrol stations and stores with a large display window area, also evening restaurants and leisure facilities, as long as their consumption focus is not on weekends, e.g. fitness and tanning studios, youth centres (see also G6).",
  G3 = "These are consumers that have a relatively constant consumption throughout the year and also over the course of the week, with a noticeable constant base load. Examples include sewage treatment plants, drinking water pumps, communal facilities in residential complexes, cold stores, stores with considerable cooling requirements, facilities with forced ventilation (e.g. parking garages).",
  G4 = "These are consumers that are almost exclusively characterised by store opening hours (workday until the evening, on Saturday until the afternoon). This is the typical profile for stores of all kinds. Hairdressers also have a similar profile. Differences due to e.g. individual afternoons without business operations are hardly significant in relation to the overall group. Store opening hours, some of which are extended to 8 p.m., also have little influence, as the effects of business operations are mixed with those of evening store lighting.",
  G5 = "Bakeries with a bakehouse traditionally have their main consumption on weekdays from around 3 a.m. and on Saturday nights from around midnight. Daytime consumption is relatively low compared to overall demand and is mainly determined by sales activities. Sales-oriented bakeries in which bakery products are prepared during business hours ('in-store baking') behave like other stores and are classified in profile G4.",
  G6 = "Commercial facilities with a clear focus on consumption at weekends. In particular, these are all businesses characterised by the leisure activities of the population: youth clubs, excursion restaurants and dining establishments, petrol stations with car washes, cinemas with food outlets, sports and leisure facilities.",
  L0 = "If there is no differentiation of farms according to profiles L1 or L2 and no classification into one of the characteristic commercial profiles can be made, this profile can be used as a good approximation. It represents the weighted average value of the total group for agricultural enterprises according to the sample drawn in 1992 to represent the RWE Energie AG energy supply area.",
  L1 = "The electricity consumption of dairy farms is characterised by the double milking and subsequent cooling of the milk. Part-time farms with e.g. pig rearing show similar behaviour: Here, electricity consumption is triggered in the early morning and evening (before and after the main occupation, respectively) by the feeding processes. In the case of large main farms with animal husbandry, such processes are distributed over the classic working hours, so that the appropriate commercial profile must be selected.",
  L2 = "Traditionally, most West German farms have a combination of household and production. This average profile should be applied to such farms. If production on a farm is largely independent of the time of day (e.g. animal production facilities in eastern Germany), the appropriate commercial profile should be selected.",
  H25 = "Representative household profile from the 2025 BDEW publication, normalised to 1,000 kWh annual consumption. This profile replaces H0 as the updated standard load profile for household customers.",
  G25 = "Representative commercial profile from the 2025 BDEW publication, normalised to 1,000 kWh annual consumption. This profile replaces G0 as the general commercial standard load profile.",
  L25 = "Representative agricultural profile from the 2025 BDEW publication, normalised to 1,000 kWh annual consumption. This profile replaces L0 as the general agricultural standard load profile.",
  P25 = "Combination profile for installations with photovoltaics (PV) from the 2025 BDEW publication, normalised to 1,000 kWh annual consumption. Represents the typical load behaviour of households with a PV system.",
  S25 = "Combination profile for installations with storage and photovoltaics (PV) from the 2025 BDEW publication, normalised to 1,000 kWh annual consumption. Represents the typical load behaviour of households with a PV system and battery storage."
)

# build info lists
infos_DE <- lapply(profiles, \(p) {
  list(
    profile = p,
    description = description_DE[[p]],
    details = details_DE[[p]]
  )
}) |>
  setNames(profiles)

infos_EN <- lapply(profiles, \(p) {
  list(
    profile = p,
    description = description_EN[[p]],
    details = details_EN[[p]]
  )
}) |>
  setNames(profiles)


# store in data/ to be accessible for users -------------------------------
usethis::use_data(slp, overwrite = TRUE)

# store data internally in R/sysdata.rda ----------------------------------
# see: https://r-pkgs.org/data.html#sec-data-sysdata
usethis::use_data(
  load_profiles_lst,
  holidays_DE,
  infos_DE,
  infos_EN,
  internal = TRUE,
  overwrite = TRUE
)
