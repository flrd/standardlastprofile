#' Retrieve information on standard load profiles
#'
#' Returns descriptions for electricity and gas standard load profiles defined
#' by BDEW. Accepts both electricity profile IDs (`H0`, `G0`–`G6`, `L0`–`L2`,
#' `H25`, `G25`, `L25`, `P25`, `S25`) and gas profile IDs (`HEF`, `HMF`,
#' `HKO`, `GKO`, `GHA`, `GMK`, `GBD`, `GBH`, `GWA`, `GGA`, `GBA`, `GGB`,
#' `GPD`, `GMF`, `GHD`).
#'
#' @param profile_id character vector of profile identifiers. Electricity and
#'   gas IDs can be mixed freely.
#' @param language one of `"EN"` (default) or `"DE"`.
#'
#' @return A named list with one element per `profile_id`. Each element is a
#'   list with character components `profile` (the identifier), `description`
#'   (a short label), and — for electricity profiles only — `details` (a
#'   longer explanation).
#'
#' @export
#'
#' @source <https://www.bdew.de/energie/standardlastprofile-strom/>
#' @source <https://www.bdew.de/energie/standardlastprofile-gas/>
#'
#' @examples
#' # Electricity profile
#' slp_info("H0")
#'
#' # Gas profile
#' slp_info("HEF")
#'
#' # Mixed
#' slp_info(c("H0", "HEF", "GKO"))
#'
#' # German descriptions
#' slp_info("HEF", language = "DE")
slp_info <- \(profile_id, language = c("EN", "DE")) {
  language <- toupper(language)
  language <- match.arg(language)

  elec_valid <- c(
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

  gas_descriptions_EN <- list(
    HEF = "Single-family home",
    HMF = "Multi-family home",
    HKO = "Cooking and hot water only",
    GKO = "Small commercial",
    GHA = "Trade and commerce",
    GMK = "Metal and automotive",
    GBD = "Services",
    GBH = "Accommodation",
    GWA = "Laundries",
    GGA = "Gastronomy",
    GBA = "Bakeries",
    GGB = "Mixed commercial",
    GPD = "Paper and printing",
    GMF = "Large multi-family / mixed use",
    GHD = "Trade, commerce and services aggregate"
  )
  gas_descriptions_DE <- list(
    HEF = "Einfamilienhaus",
    HMF = "Mehrfamilienhaus",
    HKO = "Kochen / Warmwasser",
    GKO = "Kleinstgewerbe",
    GHA = "Handel",
    GMK = "Metall / Kfz",
    GBD = "Dienstleistung",
    GBH = "Beherbergung",
    GWA = "W\u00e4scherei",
    GGA = "Gastronomie",
    GBA = "B\u00e4ckerei",
    GGB = "Gemischtes Gewerbe",
    GPD = "Papier / Druck",
    GMF = "Mehrfamilienhaus gross",
    GHD = "GHD-St\u00fctzpunkt"
  )
  gas_valid <- names(gas_descriptions_EN)

  all_valid <- c(elec_valid, gas_valid)

  if (missing(profile_id) || length(profile_id) == 0L) {
    stop("Please provide at least one value as 'profile_id'.")
  }

  profile_id <- toupper(as.character(profile_id))
  invalid <- setdiff(profile_id, all_valid)
  if (length(invalid) > 0L) {
    stop(
      "'profile_id' should be one of ",
      paste0("'", all_valid, "'", collapse = ", "),
      "."
    )
  }

  out <- lapply(profile_id, \(pid) {
    if (pid %in% elec_valid) {
      if (language == "EN") infos_EN[[pid]] else infos_DE[[pid]]
    } else {
      desc <- if (language == "EN") {
        gas_descriptions_EN[[pid]]
      } else {
        gas_descriptions_DE[[pid]]
      }
      list(profile = pid, description = desc)
    }
  })
  names(out) <- profile_id
  out
}
