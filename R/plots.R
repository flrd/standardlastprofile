# Internal plot helpers used by README.Rmd and the vignette.
# Not exported; call via standardlastprofile:::slp_plot_1999() etc.

utils::globalVariables(c("slp", "timestamp", "watts", "period"))

slp_plot_1999 <- \() {
  label_names <- c(
    "saturday" = "Saturday",
    "sunday" = "Sunday",
    "workday" = "Workday"
  )

  tmp <- slp[
    slp$profile_id %in%
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
      title = "BDEW Standard Load Profiles from 1999",
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

slp_plot_2025 <- \(months = c("december", "march", "july")) {
  label_names <- c(
    "saturday" = "Saturday",
    "sunday" = "Sunday",
    "workday" = "Workday"
  )

  tmp <- slp[
    slp$profile_id %in%
      c("H25", "G25", "L25", "P25", "S25") &
      slp$period %in% months,
  ]
  tmp$period <- factor(tmp$period, levels = months)
  tmp$day <- factor(tmp$day, levels = c("workday", "saturday", "sunday"))

  month_colours <- c(
    "december" = "#961BFA",
    "july" = "#FA9529",
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
      title = "BDEW Standard Load Profiles from 2025",
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
