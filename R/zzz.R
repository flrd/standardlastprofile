.onAttach <- \(libname, pkgname) {
  # Deprecated dataset shim (rename in 2.0.0).
  # Placed in .onAttach so the binding lands in the package *attach* environment
  # — the one on the search path — so bare `slp` works after library().
  # Only installed when data/slp.rda is absent: while the old file is still
  # present it creates a regular lazy binding first, and makeActiveBinding()
  # cannot overwrite a regular binding. Once data/slp.rda is removed (the
  # release step), this active binding becomes the sole `slp` and fires
  # the deprecation warning on every access.
  pkg_env <- as.environment(paste0("package:", pkgname))
  if (!exists("slp", envir = pkg_env, inherits = FALSE)) {
    makeActiveBinding(
      "slp",
      env = pkg_env,
      fun = \() {
        lifecycle::deprecate_warn(
          "2.0.0",
          "slp()",
          "slp_electricity_profiles()",
          details = paste(
            "The dataset has been renamed to `slp_electricity_profiles`.",
            "Access it with `standardlastprofile::slp_electricity_profiles`."
          )
        )
        slp_electricity_profiles
      }
    )
  }
}
