

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
  "commerce working day from 8am - 6pm",
  "Commerce with high to predominant consumption in the evening hours",
  "commerce continous",
  "shop / barbershop",
  "bakery with bakehouse",
  "weekend business",
  "agricultural businesses in general",
  "agricultural businesses with dairy farming / part-time livestock farming",
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

# store data internally ---------------------------------------------------
# see: https://r-pkgs.org/data.html#sec-data-sysdata

usethis::use_data(
  profile_description_DE,
  profile_description_EN,
  internal = TRUE,
  overwrite = TRUE
  )
