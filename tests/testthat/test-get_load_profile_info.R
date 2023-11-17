DE <-
  structure(
    list(
      profile = structure(
        1:11,
        levels = c("H0", "G0",
                   "G1", "G2", "G3", "G4", "G5", "G6", "L0", "L1", "L2"),
        class = "factor"
      ),
      description = c(
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
      ),
      comment = c(
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
    ),
    class = "data.frame",
    row.names = c(NA,-11L)
  )

EN <-
  structure(
    list(
      profile = structure(
        1:11,
        levels = c("H0", "G0",
                   "G1", "G2", "G3", "G4", "G5", "G6", "L0", "L1", "L2"),
        class = "factor"
      ),
      description = c(
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
      ),
      comment = c(
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
    ),
    class = "data.frame",
    row.names = c(NA,-11L)
  )

test_that("info in English as expected", {
  expect_equal(get_load_profile_info(language = "EN"), EN)
})

test_that("info in English as expected", {
  expect_equal(get_load_profile_info(language = "DE"), DE)
})
