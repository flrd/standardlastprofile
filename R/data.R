#' Standard Load Profile Data for Electricity from BDEW
#'
#' Data about representative, standard load profiles for electricity from
#' the German Association of Energy and Water Industries (BDEW Bundesverband
#' der Energie- und Wasserwirtschaft e.V.) in a tidy format.
#'
#' @format A data.frame with 26,784 observations and 5 variables:
#' \describe{
#'   \item{profile_id}{character, identifier for load profile, see 'Details'}
#'   \item{period}{character, one of `'summer'`, `'winter'`, `'transition'` for
#'     1999 profiles; one of `'january'` through `'december'` for 2025 profiles}
#'   \item{day}{character, one of `'saturday'`, `'sunday'`, `'workday'`}
#'   \item{timestamp}{character, format: %H:%M}
#'   \item{watts}{numeric, electric power in watts, normalised to 1,000 kWh/a}
#' }
#'
#' @examples
#' head(slp_electricity_profiles)
#'
#' @details
#' There are 96 x 1/4h measurements of electrical power for each combination
#' of `profile_id`, `period` and `day`, which we refer to as the "standard load
#' profile".
#'
#' In total there are 16 `profile_id` across two generations of profiles:
#'
#' **1999 profiles** (based on analysis of 1,209 load profiles of
#' low-voltage electricity consumers in Germany):
#'
#' - Households: `H0`
#' - Commercial: `G0`, `G1`, `G2`, `G3`, `G4`, `G5`, `G6`
#' - Agriculture: `L0`, `L1`, `L2`
#'
#' **2025 profiles** (updated profiles published by BDEW in 2025):
#'
#' - Households: `H25`
#' - Commercial: `G25`
#' - Agriculture: `L25`
#' - Combination profile PV: `P25`
#' - Combination profile storage and PV: `S25`
#'
#' The 2025 profiles use calendar months rather than seasons for the `period`
#' column (`'january'` through `'december'`).
#'
#' Call [slp_info()] for more information and examples.
#'
#' **Period definitions (1999 profiles)**:
#' - `summer`: May 15 to September 14
#' - `winter`: November 1 to March 20
#' - `transition`: March 21 to May 14, and September 15 to October 31
#'
#' **Day definitions**:
#' - `workday`: Monday to Friday
#' - `saturday`: Saturdays; Dec 24th and Dec 31st are also treated as Saturdays
#' unless they fall on a Sunday
#' - `sunday`: Sundays and all public holidays
#'
#' **Units and normalisation**:
#'
#' The source Excel file for the 1999 profiles stores values in watts (W),
#' normalised to an annual consumption of 1,000 kWh/a. The source Excel file
#' for the 2025 profiles stores values in kilowatt-hours (kWh) per 15-minute
#' interval, normalised to 1,000,000 kWh/a. To keep the internal representation
#' consistent and backwards compatible, all 2025 values have been converted to
#' watts normalised to 1,000 kWh/a.
#'
#' As a result, the `watts` column in both this dataset and the output of
#' [slp_electricity()] always represents average electric power in watts,
#' normalised to 1,000 kWh/a. To convert to energy consumed per 15-minute
#' interval in kWh, divide by 4 and by 1,000:
#'
#' ```r
#' watts_to_kwh <- \(x) x / 4 / 1000
#' ```
#'
#' @source <https://www.bdew.de/energie/standardlastprofile-strom/>
#' @source <https://www.bdew.de/media/documents/Profile.zip>
#' @source <https://www.bdew.de/media/documents/1999_Repraesentative-VDEW-Lastprofile.pdf>
#'
#' @aliases slp
"slp_electricity_profiles"

#' Long-term Mean Daily Temperatures from DWD Reference Stations
#'
#' Daily mean temperatures averaged over the WMO climate normal period
#' 1991–2020 for ten representative DWD (Deutscher Wetterdienst) weather
#' stations across Germany. These climatological means serve as reference
#' temperature series for deriving the Kundenwert via [slp_gas_kundenwert()].
#'
#' @format A data.frame with 3,660 observations (10 stations x 366 days) and
#'   5 variables:
#' \describe{
#'   \item{station_id}{integer, DWD station identifier}
#'   \item{station}{character, station name}
#'   \item{region}{character, climate region label}
#'   \item{date}{Date, day of the year using the reference leap year 2020
#'     (`2020-01-01` to `2020-12-31`, 366 days)}
#'   \item{temp_c_mean}{numeric, long-term mean daily temperature in °C}
#' }
#'
#' @details
#' The BDEW/VKU/GEODE Leitfaden (section 3.6.3) specifies that the Kundenwert
#' should be derived from a multi-year mean temperature series
#' (*Mehrjahresmittel*) rather than a single year, to avoid any individual-year
#' anomaly distorting the scaling factor. This dataset implements that
#' requirement using the WMO climate normal period 1991–2020.
#'
#' For each station, the mean is computed per calendar day (MM-DD) across all
#' 30 years. February 29 is averaged over the eight leap years in the period.
#' Dates use the year 2020 (a leap year) as a reference so that all 366 days
#' are represented.
#'
#' ## Stations
#'
#' | Station      | DWD ID | Elevation | Region                     |
#' |--------------|--------|-----------|----------------------------|
#' | Oberstdorf   | 3730   | 806 m     | Alpenrand / Allgaeu        |
#' | Potsdam      | 3987   |  81 m     | Kontinentales Binnenland   |
#' | Hamburg      | 1975   |  11 m     | Maritime Nordseekueste     |
#' | Freiburg     | 1443   | 237 m     | Oberrheingraben            |
#' | Chemnitz     |  853   | 416 m     | Erzgebirge / Mittelgebirge |
#' | Duesseldorf  | 1078   |  37 m     | Niederrhein                |
#' | Erfurt       | 1270   | 316 m     | Thueringer Becken          |
#' | Frankfurt    | 1420   | 112 m     | Rhein-Main-Gebiet          |
#' | Nuernberg    | 3668   | 314 m     | Mittelfranken              |
#' | Regensburg   | 4104   | 365 m     | Oberpfalz / Donau          |
#'
#' @seealso [slp_gas_kundenwert()], [slp_gas()]; the
#'   \href{https://bookdown.org/brry/rdwd/}{rdwd} package by Berry Boessenkool
#'   was used to download and process the raw DWD station data.
#'
#' @source DWD Climate Data Center (CDC): daily station observations for
#'   Germany, \url{https://opendata.dwd.de/climate_environment/CDC/observations_germany/climate/daily/kl/}
#' @source BDEW/VKU/GEODE (2025). *Abwicklung von Standardlastprofilen Gas*,
#'   Kooperationsvereinbarung Gas, Anlage XIV.2, Stand vom 28.10.2025, section
#'   3.6.3.
#'   \url{https://www.bdew.de/media/documents/251028_LF_SLP_Gas_KoV_XIV.2.pdf}
#'
#' @examples
#' head(slp_gas_normtemperatur)
#'
#' # Stations and their annual mean temperature
#' aggregate(temp_c_mean ~ station, data = slp_gas_normtemperatur, FUN = mean)
#'
#' # Use directly with slp_gas_kundenwert
#' ref <- slp_gas_normtemperatur[slp_gas_normtemperatur$station == "Hamburg", ]
#' slp_gas_kundenwert("HEF", dates = ref$date, temperatures = ref$temp_c_mean,
#'                    annual_consumption = 15000)
#' @aliases normtemperatur
"slp_gas_normtemperatur"
