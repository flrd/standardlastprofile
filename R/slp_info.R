#' Information and Examples of BDEW Standard Load Profiles
#'
#' @return A list
#'
#' @param profile_id load profile identifier, required
#' @param language one of 'EN' (English), 'DE' (German)
#' @export
#'
#' @source <https://www.bdew.de/energie/standardlastprofile-strom/>
#' @source <https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf>
#' @source <https://www.bdew.de/media/documents/Zuordnung_der_VDEW-Lastprofile_zum_Kundengruppenschluessel.pdf>
#'
#' @examples
#' slp_info("G5", language = "DE")
#'
slp_info <- function(profile_id, language = c("EN", "DE")) {

  match_profile(profile_id)

  language <- toupper(language)
  language <- match.arg(language)

  if (language == "EN") {
    out <- infos_EN[[profile_id]]
  } else {
    out <- infos_DE[[profile_id]]
  }
  out
}
