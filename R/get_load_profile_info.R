#' Get the description load profiles according to the BDEW
#'
#' @return A data.frame
#'
#' @param language one of 'EN' (English), 'DE' (German)
#' @export
#'
#' @source <https://www.bdew.de/energie/standardlastprofile-strom/>
#' @source <https://www.bdew.de/media/documents/2000131_Anwendung-repraesentativen_Lastprofile-Step-by-step.pdf>
#'
#' @examples
#' get_load_profile_info(language = "EN")$G6
#' get_load_profile_info(language = "DE")$G6
#'
get_load_profile_info <- function(language = c("EN", "DE")) {

  language <- toupper(language)
  language <- match.arg(language)

  if (language == "EN") {
    out <- infos_EN
  } else {
    out <- infos_DE
  }
  return(out)
}
