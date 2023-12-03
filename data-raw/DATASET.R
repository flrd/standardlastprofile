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
slp_lst <- vector(mode = "list", length = n_sheets)
names(slp_lst) <- sheets

# populate list
for (sheet in sheets) {
  slp_lst[[sheet]] <- readxl::read_excel(
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

slp_lst <- lapply(slp_lst, function(profile) {
  # use data.table, set profile to
  data.table::setDT(profile)

  # rename columns
  data.table::setnames(profile, c(nms[1], paste(days, nms[-1], sep = "_")))

  # remove date part from 'timestamp' column; start at 00:00
  profile[, timestamp := format(timestamp, "%H:%M")]
  profile[, timestamp := c(timestamp[.N], timestamp[-.N])]
})


# create list of matrices to be used internally ---------------------------
load_profiles_lst <- lapply(slp_lst, function(profile) {
  as.matrix(profile, rownames = "timestamp")
})


# create .csv to be added in inst/extdata ---------------------------------
slp <- lapply(slp_lst, function(profile) {
  # reshape from wide to long format
  profile <- data.table::melt(profile,
                              measure.vars = patterns(days),
                              value.name = days,
                              variable.factor = TRUE)

  # set values in column 'type' to appropriate period, remove column 'variable'
  profile[, period := `levels<-`(variable, periods)]
  profile[, period := as.character(period)]
  profile[, variable := NULL]
  profile

}) |>
  data.table::rbindlist(idcol = "profile_id") |>
  data.table::melt(
    measure.vars = c("saturday", "sunday", "workday"),
    variable.name = "day",
    variable.factor = FALSE,
    value.name = "watts"
) |>
  data.table::setcolorder(c("profile_id", "period", "day", "timestamp", "watts")) |>
  as.data.frame()

# save as .csv
fwrite(x = slp,
       file = system.file("/inst/extdata", "slp.csv", package = "standardlastprofile"))


# state names -------------------------------------------------------------

german_states <-
  structure(list(
    state_code = c(
      "DE-BW",
      "DE-BY",
      "DE-ST",
      "DE-BE",
      "DE-MV",
      "DE-SL",
      "DE-RP",
      "DE-NW",
      "DE-HE",
      "DE-SH",
      "DE-NI",
      "DE-BB",
      "DE-HH",
      "DE-HB",
      "DE-SN",
      "DE-TH"
    ),
    state_de = c(
      "Baden-Württemberg",
      "Bayern",
      "Sachsen-Anhalt",
      "Berlin",
      "Mecklenburg-Vorpommern",
      "Saarland",
      "Rheinland-Pfalz",
      "Nordrhein-Westfalen",
      "Hessen",
      "Schleswig-Holstein",
      "Niedersachsen",
      "Brandenburg",
      "Hamburg",
      "Bremen",
      "Sachsen",
      "Thüringen"
    ),
    state_en = c(
      "Baden-Württemberg",
      "Bavaria",
      "Saxony-Anhalt",
      "Berlin",
      "Mecklenburg-Vorpommern",
      "Saarland",
      "Rhineland-Palatinate",
      "North Rhine-Westphalia",
      "Hesse",
      "Schleswig-Holstein",
      "Lower-Saxony",
      "Brandenburg",
      "Hamburg",
      "Bremen",
      "Saxony",
      "Thuringia"
    )
  ),
  class = "data.frame",
  row.names = c(NA,-16L))

# to be exported
usethis::use_data(german_states, overwrite = TRUE)

# fetch public holidays in Germany from nager.Date API --------------------

# extract nationwide holidays
is_nationwide <- function(x) {
  x[["global"]]
}

get_holidays_DE <- function(year) {
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
      FUN = function(x) x[["date"]],
      FUN.VALUE = character(1)
    )
  )

  # idx_states <- vapply(resp_body, Negate(is_nationwide), logical(1))
  holidays_states <- lapply(resp_body[!idx_nation], function(x) {
    data.frame(
      holiday = x[["date"]],
      region = unlist(x["counties"], use.names = FALSE)
    )
  }) |> do.call(rbind, args = _)

  # combine national and regional holidays into 1 data.frame
  out <- rbind(holidays_nationwide, holidays_states)

  # add year column and return data.frame
  cbind(data.frame(year = year), out)
}

years <- seq.int(1990, 2073)

# fetch holidays for every year in years
holidays_DE <- lapply(years, get_holidays_DE)

# creates a single data.frame for all years
holidays_DE <- do.call(rbind, holidays_DE)

# abbreviations of the 11 profiles included in this package ---------------
profiles <- c("H0", "G0", "G1", "G2", "G3", "G4", "G5", "G6", "L0", "L1", "L2")

# German description ------------------------------------------------------
description_DE = c(
  H0 = "Haushalt",
  G0 = "Gewerbe allgemein",
  G1 = "Gewerbe werktags 8-18 Uhr",
  G2 = "Gewerbe mit starkem bis überwiegendem Verbrauch in den Abendstunde",
  G3 = "Gewerbe durchlaufend",
  G4 = "Laden/ Friseur",
  G5 = "Bäckerei mit Backstube",
  G6 = "Wochenendbetrieb",
  L0 = "Landwirtschaftsbetriebe allgemein",
  L1 = "Landwirtschaftsbetriebe mit Milchwirtschaft/ Nebenerwerbs-Tierzucht",
  L2 = "Übrige Landwirtschaftsbetriebe"
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
  L2 = "Traditionell findet sich bei den meisten westdeutschen Betrieben ein Nebeneinander von Haushalt und Produktion. Für solche Betriebe ist dieses mittlere Profil anzuwenden. Soweit in einem landwirtschaftlichen Betrieb eine weitgehend tageszeitenunabhängige Produktion vorliegt (z.B. Tierproduktionsanlagen in Ostdeutschland), ist das passende Gewerbe-Profil zu wählen."
)

# English description -----------------------------------------------------
description_EN = c(
  H0 = "household",
  G0 = "commerce in general",
  G1 = "commerce workday from 8am - 6pm",
  G2 = "commerce with predominant consumption in evening hours",
  G3 = "commerce continous",
  G4 = "shop / barbershop",
  G5 = "bakery with bakehouse",
  G6 = "weekend business",
  L0 = "agricultural in general",
  L1 = "agricultural with dairy farming / part-time livestock farming",
  L2 = "other agricultural businesses"
)

details_EN = c(
  H0 = "This profile includes all households with exclusively and predominantly private consumption. Households with predominantly private electrical consumption, i.e. also with minor commercial consumption are e.g. sales representatives, home workers, etc. with an office in the household. The Household profile is not applicable for special applications such as storage heaters or heat pumps.",
  G0 = "If an assignment to one of the profiles G1 to G6 is not possible or desired, this profile represents the weighted average of the overall group.",
  G1 = "This profile represents consumers that typically use electricity between around 8 a.m. and 6 p.m. on weekdays, with little or no consumption on weekends (otherwise see G4). These include offices, doctors' offices, law firms, workshops, print shops, schools, kindergartens and daycare centers, administrative facilities and branch banks.",
  G2 = "This profile mainly includes illumination-intensive electricity consumption. Such businesses are characterized by a rather subordinate daily demand on working days (especially in the winter season) and a consumption focus in the evening hours. These include, for example, petrol stations and stores with a large display window area, also evening restaurants and leisure facilities, as long as their consumption focus is not on weekends, e.g. fitness and tanning studios, youth centers (see also G6).",
  G3 = "These are consumers that have a relatively constant consumption throughout the year and also over the course of the week, with a noticeable constant base load. Examples include sewage treatment plants, drinking water pumps, communal facilities in residential complexes, cold stores, stores with considerable cooling requirements, facilities with forced ventilation (e.g. parking garages).",
  G4 = "These are consumers that are almost exclusively characterized by store opening hours (workday until the evening, on Saturday until the afternoon). This is the typical profile for stores of all kinds. Hairdressers also have a similar profile. Differences due to e.g. individual afternoons without business operations are hardly significant in relation to the overall group. Store opening hours, some of which are extended to 8 p.m., also have little influence, as the effects of business operations are mixed with those of evening store lighting.",
  G5 = "Bakeries with a bakery traditionally have their main consumption on weekdays from around 3 a.m. and on Saturday nights from around midnight. Daytime consumption is relatively low compared to overall demand and is mainly determined by sales activities. Sales-oriented bakeries in which bakery products are prepared during business hours ('in-store baking') behave like other stores and are classified in profile G4.",
  G6 = "Commercial facilities with a clear focus on consumption at weekends. In particular, these are all businesses characterized by the leisure activities of the population: youth clubs, restaurants and cafés, petrol stations with car washes, cinemas with food outlets, sports and leisure facilities.",
  L0 = "If there is no differentiation of farms according to profiles L1 or L2 and no classification into one of the characteristic commercial profiles can be made, this profile can be used as a good approximation. It represents the weighted average value of the total group for agricultural enterprises according to the sample drawn in 1992 to represent the RWE Energie AG energy supply area.",
  L1 = "The electricity consumption of dairy farms is characterized by the double milking and subsequent cooling of the milk. Part-time farms with e.g. pig rearing show similar behavior: Here, electricity consumption is triggered in the early morning and evening (before and after the main farm respectively) by the feeding processes. In the case of large main farms with animal husbandry, such processes are distributed over the classic working hours, so that the appropriate commercial profile must be selected.",
  L2 = "Traditionally, most West German companies have a combination of household and production. This average profile should be applied to such farms. If production on a farm is largely independent of the time of day (e.g. animal production facilities in in eastern Germany), the appropriate commercial profile should be selected."
)


# create data.frame and store internally ----------------------------------

infos_DE <- vector("list", length(profiles))
names(infos_DE) <- profiles

for (profile in profiles) {
  infos_DE[[profile]] = list(profile = profile,
                             description = description_DE[[profile]],
                             details = details_DE[[profile]])
}

infos_EN <- vector("list", length(profiles))
names(infos_EN) <- profiles

for (profile in profiles) {
  infos_EN[[profile]] = list(profile = profile,
                             description = description_EN[[profile]],
                             details = details_EN[[profile]])
}


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
