#' Get the description load profiles according to the BDEW
#'
#' @return A data.frame
#'
#' @param language One of 'EN' (English), 'DE' (German)
#' @export
#'
#' @source https://www.bdew.de/energie/standardlastprofile-strom/
#' @examples
#' get_profile_info(language = "EN")
#' get_profile_info(language = "DE")
#'
get_load_profile_info <- function(language = c("EN", "DE")) {

  language <- toupper(language)
  language <- match.arg(language)

  if (language == "EN") {
    out <- profile_description_EN
  } else {
    out <- profile_description_DE
  }
  return(out)
}
