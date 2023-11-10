#' Representative BDEW load profiles
#'
#'The use of standard load profiles (SLP) is a simplification. This data set contains
#'eleven profiles for the energy type electricity; there is data for three different
#'customer types, three different annual periods and three different days of the week.
#'
#' @format ## `load_profiles`
#' A data frame with 9,504 rows and 5 columns:
#' \describe{
#'   \item{profile}{One of 11 standardized load profiles.}
#'   \item{period}{...}
#'   \item{weekyday}{BDEW distinguishes between 'saturday', 'sunday', and 'week_day'; public holidays are considered 'sunday'(s).}
#'   \item{timestamp}{Timestemp in quarterly hour intervals from '00:15' to '00:00' in format '%H-%M'.}
#'   \item{value}{...}
#' }
#' @source <https://www.bdew.de/energie/standardlastprofile-strom/>
"load_profiles"
