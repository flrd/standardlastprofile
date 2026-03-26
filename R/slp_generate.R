#' Generate a Standard Load Profile for Electricity
#'
#' `r lifecycle::badge("superseded")`
#'
#' Please use [slp_electricity()] instead.
#'
#' @inheritParams slp_electricity
#' @param state_code `r lifecycle::badge("defunct")` Removed in version 2.0.0.
#'   Use `holidays` instead.
#'
#' @return See [slp_electricity()].
#'
#' @importFrom lifecycle deprecated
#' @export
#' @keywords internal
#' @examples
#' # Superseded — use slp_electricity() instead:
#' \dontrun{
#' slp_generate("H0", "2026-01-01", "2026-12-31")
#' }
slp_generate <- \(
  profile_id,
  start_date,
  end_date,
  holidays = NULL,
  state_code = deprecated()
) {
  lifecycle::deprecate_soft(
    "2.0.0",
    "slp_generate()",
    "slp_electricity()"
  )

  if (lifecycle::is_present(state_code)) {
    lifecycle::deprecate_stop(
      "2.0.0",
      "slp_generate(state_code)",
      "slp_electricity(holidays)"
    )
  }

  slp_electricity(
    profile_id = profile_id,
    start_date = start_date,
    end_date = end_date,
    holidays = holidays
  )
}
