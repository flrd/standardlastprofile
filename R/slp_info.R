#' Details and Examples of standard load profiles
#'
#' @return A data.frame
#'
#' @param language one of 'EN' (English), 'DE' (German)
#' @export
#'
#' @source <https://www.bdew.de/energie/standardlastprofile-strom/>
#' @source <https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf>
#' @source <https://www.bdew.de/media/documents/Zuordnung_der_VDEW-Lastprofile_zum_Kundengruppenschluessel.pdf>
#'
#' @examples
#' slp_info(language = "EN")$G6
#' slp_info(language = "DE")$G6
#'
slp_info <- function(language = c("EN", "DE")) {

  language <- toupper(language)
  language <- match.arg(language)

  if (language == "EN") {
    out <- infos_EN
  } else {
    out <- infos_DE
  }
  return(out)
}