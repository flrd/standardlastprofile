.onAttach <- \(libname, pkgname) {
  # Deprecated dataset shim (rename in 2.0.0).
  # Placed in .onAttach so the binding lands in the package *attach* environment
  # — the one on the search path — so bare `slp` works after library().
  # Only installed when data/slp.rda is absent: while the old file is still
  # present it creates a regular lazy binding first, and makeActiveBinding()
  # cannot overwrite a regular binding. Once data/slp.rda is removed (the
  # release step), this active binding becomes the sole `slp` and fires
  # the deprecation warning on every access.
  # Skip while running under R CMD check: its undoc()/codoc() introspection
  # get()s every attached object, which would force this binding to evaluate
  # and emit the deprecation warning, failing the check. End users are never
  # under check, so they still get the warning on access.
  if (nzchar(Sys.getenv("_R_CHECK_PACKAGE_NAME_"))) {
    return(invisible())
  }
  pkg_env <- as.environment(paste0("package:", pkgname))
  if (!exists("slp", envir = pkg_env, inherits = FALSE)) {
    makeActiveBinding(
      "slp",
      env = pkg_env,
      fun = \() {
        stop(
          "`slp` was renamed to `slp_electricity_profiles` and is defunct as of ",
          "standardlastprofile 2.1.0.\n",
          "Use `slp_electricity_profiles` or ",
          "`standardlastprofile::slp_electricity_profiles` instead.",
          call. = FALSE
        )
      }
    )
  }
}
