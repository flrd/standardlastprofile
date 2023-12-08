#' Standard Load Profile Data for Electricity from BDEW
#'
#'Data about representative, standard load profiles for electricity from
#'the German Association of Energy and Water Industries (BDEW Bundesverband
#'der Energie- und Wasserwirtschaft e.V.) in a tidy format.
#'
#' @format A data.frame with 9,504 observations and 5 variables:
#' \describe{
#'   \item{profile_id}{character, identifier for load profile, see 'Details'}
#'   \item{period}{character, one of 'summer', 'winter', 'transition'}
#'   \item{day}{character, one of 'saturday', 'sunday', 'workday'}
#'   \item{timestamp}{character, format: %H:%M}
#'   \item{watt}{numeric, electric power}
#' }
#'
#'@examples
#'head(slp)
#'
#'@details
#'There are 96 x 1/4h measurements of electrical power for each combination
#'of `profile_id`, `period` and `day`, which we refer to as the "standard load
#'profile". This dataset results from an analysis of 1,209 load profiles of
#'low-voltage electricity consumers in Germany, published in 1999.
#'
#' In total there are 11 `profile_id` for three different customer groups:
#'
#' - Households: `H0`
#' - Commercial: `G0`, `G1`, `G2`, `G3`, `G4`, `G5`, `G6`
#' - Agriculture: `L0`, `L1`, `L2`
#'
#' Call [slp_info()] to for more information and examples.
#'
#' Period definitions:
#' - `summer`: May 15 to September 14
#' - `winter`: November 1 to March 20
#' - `transition`: March 21 to May 14, and September 15 to October 31
#'
#' Day definitions:
#' - `workday`: Monday to Friday
#' - `saturday`: Saturdays; Dec 24th and Dec 31th are considered a Saturdays too
#'if they are not a Sunday
#' - `sunday`: Sundays and all public holidays
#'
#' @source <https://www.bdew.de/energie/standardlastprofile-strom/>
#' @source <https://www.bdew.de/media/documents/Profile.zip>
#' @source <https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf>
#'
"slp"

