DE <- list(
  H0 = list(
    profile = "H0",
    description = "Haushalt",
    details = "In dieses Profil werden alle Haushalte mit ausschließlichem und überwiegendem Privatverbrauch eingeordnet. Haushalte mit überwiegend privatem elektrischen Verbrauch, d.h. auch mit geringfügigem gewerblichen Bedarf sind z.B. Handelsvertreter, Heimarbeiter u.ä. mit Büro im Haushalt. Das Profil Haushalt ist nicht anwendbar bei Sonderanwendungen wie z.B. elektrischen Speicherheizungen oder Wärmepumpen."
  )
)

EN <- list(
  H0 = list(
    profile = "H0",
    description = "household",
    details = "This profile includes all households with exclusively and predominantly private consumption. Households with predominantly private electrical consumption, i.e. also with minor commercial consumption are e.g. sales representatives, home workers, etc. with an office in the household. The Household profile is not applicable for special applications such as storage heaters or heat pumps."
  )
)

test_that("slp_info returns electricity profile info in English", {
  expect_equal(EN["H0"], slp_info("H0", language = "EN"))
})

test_that("slp_info returns electricity profile info in German", {
  expect_equal(DE["H0"], slp_info("H0", language = "DE"))
})

test_that("slp_info returns gas profile info in English", {
  out <- slp_info("HEF")
  expect_equal(out$HEF$profile, "HEF")
  expect_equal(out$HEF$description, "Single-family home")
})

test_that("slp_info returns gas profile info in German", {
  out <- slp_info("HEF", language = "DE")
  expect_equal(out$HEF$profile, "HEF")
  expect_equal(out$HEF$description, "Einfamilienhaus")
})

test_that("slp_info handles mixed electricity and gas IDs", {
  out <- slp_info(c("H0", "HEF"))
  expect_named(out, c("H0", "HEF"))
  expect_match(out$H0$description, "household")
  expect_equal(out$HEF$description, "Single-family home")
})

test_that("slp_info rejects invalid profile IDs", {
  expect_error(slp_info("ABC"), "'profile_id' should be one of")
})
