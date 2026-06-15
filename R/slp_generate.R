#' Generate a Standard Load Profile for Electricity
#'
#' **Defunct.** Please use [slp_electricity()] instead.
#'
#' @inheritParams slp_electricity
#' @param state_code Removed in version 2.0.0. Use `holidays` instead.
#'
#' @return See [slp_electricity()].
#'
#' @export
#' @keywords internal
#' @examples
#' # Defunct — use slp_electricity() instead:
#' \dontrun{
#' slp_generate("H0", "2026-01-01", "2026-12-31")
#' }
slp_generate <- \(
  profile_id,
  start_date,
  end_date,
  holidays = NULL,
  state_code = NULL
) {
  stop(
    "`slp_generate()` was renamed to `slp_electricity()` and is defunct as of ",
    "standardlastprofile 2.1.0.\n",
    "Please use `slp_electricity()` instead.",
    call. = FALSE
  )
}
