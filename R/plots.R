# Internal plot helpers used by README.Rmd and the articles.
# Not exported; call via standardlastprofile:::.slp_plot_1999() etc.

utils::globalVariables(c(
  "slp_electricity_profiles",
  "timestamp",
  "watts",
  "period",
  "kwh",
  "day",
  "city",
  "variant",
  "delta_kwh",
  "dom"
))

.slp_plot_1999 <- \() {
  label_names <- c(
    "saturday" = "Saturday",
    "sunday" = "Sunday",
    "workday" = "Workday"
  )

  tmp <- slp_electricity_profiles[
    slp_electricity_profiles$profile_id %in%
      c("H0", "G0", "G1", "G2", "G3", "G4", "G5", "G6", "L0", "L1", "L2"),
  ]
  tmp$day <- factor(tmp$day, levels = c("workday", "saturday", "sunday"))

  ggplot2::ggplot(
    tmp,
    ggplot2::aes(
      x = as.POSIXct(paste(Sys.Date(), timestamp)),
      y = watts,
      color = period
    )
  ) +
    ggplot2::geom_line() +
    ggplot2::facet_grid(
      profile_id ~ day,
      labeller = ggplot2::labeller(day = ggplot2::as_labeller(label_names))
    ) +
    ggplot2::scale_x_datetime(
      NULL,
      date_breaks = "6 hours",
      date_labels = "%k:%M"
    ) +
    ggplot2::scale_y_continuous(
      NULL,
      breaks = c(0, 200, 400),
      limits = c(0, NA),
      labels = \(x) paste(x, "W")
    ) +
    ggplot2::scale_color_manual(
      name = NULL,
      values = c(
        "winter" = "#961BFA",
        "summer" = "#FA9529",
        "transition" = "#0CC792"
      )
    ) +
    ggplot2::labs(
      title = "SLP Electricity 1999",
      subtitle = "96 x 1/4h measurements [in watts], based on consumption of 1,000 kWh/a",
      caption = "data: www.bdew.de"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      legend.position = "top",
      strip.text.y.right = ggplot2::element_text(angle = 0),
      panel.grid.minor.x = ggplot2::element_blank(),
      panel.grid.minor.y = ggplot2::element_blank(),
      panel.grid = ggplot2::element_line(
        linetype = "12",
        lineend = "round",
        colour = "#FAF6F4"
      )
    )
}

.slp_plot_gas_cities <- \(
  profile_id = "HEF",
  annual_consumption = 15000
) {
  # Smooth climatological temperature series. Parameters follow long-term DWD
  # normals. Düsseldorf is the baseline; the three comparison cities are shown
  # as daily deviations from it.
  dates <- seq.Date(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "day")
  doy <- as.integer(format(dates, "%j"))
  clim <- \(mean, amp) mean - amp * cos(2 * pi * (doy - 15) / 365)

  city_temps <- list(
    Duesseldorf = clim(11.1, 9.0),
    Chemnitz = clim(9.0, 11.5),
    Freiburg = clim(11.5, 9.5),
    Hamburg = clim(10.0, 10.0)
  )

  # Fixed KW from Düsseldorf reference year, variant 34.
  kw_ref <- slp_gas_kundenwert(
    profile_id,
    dates,
    city_temps[["Duesseldorf"]],
    annual_consumption = annual_consumption,
    variant = "34"
  )

  # Generate profiles for all cities with the same KW.
  all_out <- lapply(names(city_temps), \(ct) {
    out <- slp_gas(
      profile_id,
      dates,
      city_temps[[ct]],
      kundenwert = kw_ref,
      variant = "34"
    )
    out$city <- ct
    out
  })
  dat <- do.call(rbind, all_out)

  # Compute daily difference versus Düsseldorf.
  ref_kwh <- dat$kwh[dat$city == "Duesseldorf"]
  dat_cmp <- dat[dat$city != "Duesseldorf", ]
  dat_cmp$delta_kwh <- dat_cmp$kwh - rep(ref_kwh, 3L)

  dat_cmp$month <- factor(format(dat_cmp$date, "%b"), levels = month.abb)
  dat_cmp$dom <- as.integer(format(dat_cmp$date, "%d"))
  dat_cmp$city <- factor(
    dat_cmp$city,
    levels = c("Chemnitz", "Freiburg", "Hamburg")
  )

  kw_label <- format(round(kw_ref, 1), nsmall = 1)

  ggplot2::ggplot(dat_cmp, ggplot2::aes(dom, delta_kwh, fill = delta_kwh > 0)) +
    ggplot2::geom_col(width = 0.8, show.legend = FALSE) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.25, colour = "grey50") +
    ggplot2::facet_grid(month ~ city, switch = "y") +
    ggplot2::scale_x_continuous(
      NULL,
      breaks = c(1, 15, 28),
      minor_breaks = NULL
    ) +
    ggplot2::scale_y_continuous(NULL, minor_breaks = NULL) +
    ggplot2::scale_fill_manual(
      values = c("TRUE" = "#961BFA", "FALSE" = "#FA9529")
    ) +
    ggplot2::labs(
      title = paste0(
        "SLP Gas — ",
        profile_id,
        " (KW = ",
        kw_label,
        " kWh/day): daily difference vs. Düsseldorf"
      ),
      subtitle = paste0(
        "Purple: more gas than in Düsseldorf · ",
        "Orange: less gas · ",
        "Variant 34 · ",
        format(annual_consumption, big.mark = ","),
        " kWh/a reference"
      ),
      caption = "Profile parameters: BDEW Leitfaden, as of 2025-10-28"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      strip.text.y.left = ggplot2::element_text(angle = 0),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(
        linetype = "12",
        lineend = "round",
        colour = "#FAF6F4"
      ),
      panel.spacing = ggplot2::unit(0.25, "lines")
    )
}

.slp_plot_2025 <- \(months = c("december", "march", "june")) {
  label_names <- c(
    "saturday" = "Saturday",
    "sunday" = "Sunday",
    "workday" = "Workday"
  )

  tmp <- slp_electricity_profiles[
    slp_electricity_profiles$profile_id %in%
      c("H25", "G25", "L25", "P25", "S25") &
      slp_electricity_profiles$period %in% months,
  ]
  tmp$period <- factor(tmp$period, levels = months)
  tmp$day <- factor(tmp$day, levels = c("workday", "saturday", "sunday"))

  month_colours <- c(
    "december" = "#961BFA",
    "june" = "#FA9529",
    "march" = "#0CC792"
  )

  ggplot2::ggplot(
    tmp,
    ggplot2::aes(
      x = as.POSIXct(paste(Sys.Date(), timestamp)),
      y = watts,
      color = period,
      group = period
    )
  ) +
    ggplot2::geom_line(alpha = 0.8) +
    ggplot2::facet_grid(
      profile_id ~ day,
      labeller = ggplot2::labeller(day = ggplot2::as_labeller(label_names))
    ) +
    ggplot2::scale_x_datetime(
      NULL,
      date_breaks = "6 hours",
      date_labels = "%k:%M"
    ) +
    ggplot2::scale_y_continuous(
      NULL,
      breaks = c(0, 200, 400),
      limits = c(0, NA),
      labels = \(x) paste(x, "W")
    ) +
    ggplot2::scale_color_manual(name = NULL, values = month_colours[months]) +
    ggplot2::labs(
      title = "SLP Electricity 2025",
      subtitle = "96 x 1/4h measurements [in watts], based on consumption of 1,000 kWh/a",
      caption = "data: www.bdew.de"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      legend.position = "top",
      strip.text.y.right = ggplot2::element_text(angle = 0),
      panel.grid.minor.x = ggplot2::element_blank(),
      panel.grid.minor.y = ggplot2::element_blank(),
      panel.grid = ggplot2::element_line(
        linetype = "12",
        lineend = "round",
        colour = "#FAF6F4"
      )
    )
}
