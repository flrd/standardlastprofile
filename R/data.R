#' BDEW load profiles for electricity
#'
#'Data on representative load profiles for electricity provided by the German Association of Energy and
#'Water Industries (BDEW Bundesverband der Energie- und Wasserwirtschaft e.V.). A load profile
#'shows the variation in the electrical load versus time. Each profile contains 96 quarter-hour values
#'for three different days of the week ('working_day', 'saturday', 'sunday'), three different periods
#'of the year ('summer', 'winter', 'transition'), i.e. a total of 3x3x96 observations per profile.
#'See 'Details' for more information.
#'
#' @format ## `load_profiles`
#' A data frame with 9,504 rows and 5 columns:
#' \describe{
#'   \item{profile}{One of 11 load profiles.}
#'   \item{period}{One of 3 different annual periods: summer, winter, transition.}
#'   \item{weekyday}{One of 'saturday', 'sunday', and 'working_day'.}
#'   \item{timestamp}{Timestemp in quarterly hour intervals from '00:15' to '00:00'.}
#'   \item{value}{Electricity load in Watt.}
#' }
#'
#'@details
#'Included are eleven representative load *profiles* covering three different
#'customer groups:
#'- households: 'H0'
#'- commercial: 'G0', 'G1', 'G2', 'G3', 'G4', 'G5', 'G6'
#'- agriculture: 'L0', 'L1', 'L2'
#'
#'Call [get_profile_info()] to get description for each profile.
#'
#'The definition of each *period* follows the BDEW:
#'- summer: May 15 to September 14
#'- winter: November 1 to March 20
#'- transition: March 21 to May 14, and September 15 to October 31
#'
#'In addition, a distinction is made between three different type of days:
#'- 'working_day': Monday to Friday
#'- 'saturday': Saturdays; Dec 24th and Dec 31th are considered a 'saturday' too, if they are not a 'sunday'
#'- 'sunday': Sundays and all public holidays
#'
#' @source <https://www.bdew.de/energie/standardlastprofile-strom/>
#' @source <https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf>
"load_profiles"
