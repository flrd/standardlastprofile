.onLoad <- \(libname, pkgname) {
  # Deprecated dataset shims (renames in 2.0.0). Notes:
  # - lifecycle requires function-call syntax for `what` and `with`, so the
  #   dataset names are written with parens even though they are not functions.
  # - The body uses getExportedValue() so that R CMD check's namespace
  #   introspection can resolve the lazy-loaded data via the same mechanism as
  #   the `::` operator, regardless of whether the data has been loaded yet.
  # - is_introspection_call() suppresses the deprecation warning when the
  #   active binding is read from R CMD check's namespace enumeration paths,
  #   so the warning text does not contaminate check output.

  makeActiveBinding("slp", env = asNamespace(pkgname), fun = \() {
    if (!is_introspection_call(sys.calls())) {
      lifecycle::deprecate_warn(
        "2.0.0",
        "slp()",
        "slp_electricity_profiles()",
        details = paste(
          "The dataset has been renamed to `slp_electricity_profiles`.",
          "Access it with `standardlastprofile::slp_electricity_profiles`."
        )
      )
    }
    getExportedValue(pkgname, "slp_electricity_profiles")
  })
}

# Returns TRUE when the package is being inspected by R CMD check, so the
# deprecation warning attached to the dataset active bindings can be suppressed
# during check phases. User-facing access never matches either condition.
is_introspection_call <- \(calls) {
  # During an in-flight R CMD check, R_LIBS_USER points into the per-package
  # `<pkg>.Rcheck/` directory created by the check process. That path only
  # exists for the duration of the check, so it is a uniquely reliable signal
  # that we are running inside check.
  if (grepl("\\.Rcheck", Sys.getenv("R_LIBS_USER"), fixed = FALSE)) {
    return(TRUE)
  }
  introspection_funs <- c(
    "as.list.environment",
    "checkFFmy",
    "find_bad_closures",
    "funs_in_env",
    "gens_in_env",
    ".is_S3_generic"
  )
  for (cl in calls) {
    head <- cl[[1L]]
    if (is.symbol(head) && as.character(head) %in% introspection_funs) {
      return(TRUE)
    }
  }
  FALSE
}

#' Deprecated: use `slp_gas_kundenwert()`
#'
#' `slp_kundenwert()` was renamed to [slp_gas_kundenwert()] in version 2.0.0.
#' This shim forwards to the new function and emits a deprecation warning. It
#' will be removed in a future release.
#'
#' @inheritParams slp_gas_kundenwert
#' @keywords internal
#' @export
slp_kundenwert <- \(
  profile_id,
  dates = NULL,
  temperatures = NULL,
  station = NULL,
  annual_consumption = 1000,
  variant = c("34", "33"),
  holidays = NULL
) {
  lifecycle::deprecate_warn(
    "2.0.0",
    "slp_kundenwert()",
    "slp_gas_kundenwert()"
  )
  slp_gas_kundenwert(
    profile_id = profile_id,
    dates = dates,
    temperatures = temperatures,
    station = station,
    annual_consumption = annual_consumption,
    variant = variant,
    holidays = holidays
  )
}
