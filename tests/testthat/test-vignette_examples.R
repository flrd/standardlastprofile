H0_2024 <- slp_generate(
  profile_id = "H0",
  start_date = "2024-01-01",
  end_date = "2024-12-31"
)

# aggregate by day of year as decimal number (1 - 365)
H0_2024_daily <- by(
  H0_2024,
  INDICES = format(H0_2024$start_time, "%j"),
  FUN = \(x) {
    data.frame(
      start_time = x[["start_time"]][1],
      watts = mean(x[["watts"]])
    )
  }
)
H0_2024_daily <- do.call(rbind, args = H0_2024_daily)

# example -----------------------------------------------------------------
p3 <- ggplot2::ggplot(H0_2024_daily, ggplot2::aes(start_time, watts)) +
  ggplot2::geom_line(color = "#0CC792") +
  ggplot2::scale_y_continuous(NULL, labels = \(x) paste(x, "W")) +
  ggplot2::labs(
    title = "Profile 'H0': Households",
    subtitle = "Electrical power per day",
    caption = "data: www.bdew.de",
    x = NULL
  ) +
  ggplot2::theme_minimal() +
  ggplot2::theme(
    panel.grid.minor.x = ggplot2::element_blank(),
    panel.grid.minor.y = ggplot2::element_blank(),
    panel.grid = ggplot2::element_line(
      linetype = "12",
      lineend = "round",
      colour = "#FAF6F4"
    )
  ) +
  NULL

test_that("vignette example H0 works", {
  withr::with_locale(c(LC_TIME = "C"), {
    vdiffr::expect_doppelganger("vignetee example 'H0'", p3)
  })
})


# H0_dynamic --------------------------------------------------------------

lst <- Map(
  paste,
  list("1997-01", "1996-07", "1997-04"),
  list(17:19, 19:21, 18:20),
  sep = "-"
)

periods <- c("winter", "summer", "transition")
names(lst) <- periods

days <- c("workday", "saturday", "sunday")
lst <- lapply(lst, setNames, days)

out <- vector("list", length(periods))
names(out) <- periods

for (i in periods) {
  out[[i]] <- slp_generate("H0", lst[[i]][[1]], lst[[i]][[3]])
}

out <- lapply(out, \(x) {
  wday <- as.integer(format(as.Date(x$start_time), "%u"))
  tmp <- ifelse(wday <= 5, "workday", ifelse(wday == 6, "saturday", "sunday"))
  cbind(x, data.frame(day = tmp))
})

H0 <- lapply(names(out), \(x) {
  cbind(out[[x]], data.frame(period = x))
})
H0 <- do.call(rbind, H0)
H0$timestamp <- format(H0$start_time, "%H:%M")
H0 <- H0[, names(slp)]
H0$type <- "dynamic"

H0_slp <- subset(slp, subset = profile_id == "H0")
H0_slp$type <- "static"

H0_plot <- rbind(H0, H0_slp)
H0_plot$day <- factor(H0_plot$day, levels = days)

label_names <- c(
  "saturday" = "Saturday",
  "sunday" = "Sunday",
  "workday" = "Workday"
)

p4 <- ggplot2::ggplot(
  H0_plot,
  ggplot2::aes(
    x = as.POSIXct(paste(Sys.Date(), timestamp)),
    y = watts,
    color = period
  )
) +
  ggplot2::geom_line() +
  ggplot2::facet_grid(
    day ~ type,
    labeller = ggplot2::labeller(day = ggplot2::as_labeller(label_names))
  ) +
  ggplot2::scale_x_datetime(
    NULL,
    date_breaks = "6 hours",
    date_labels = "%k:%M"
  ) +
  ggplot2::scale_y_continuous(NULL, labels = \(x) paste(x, "W")) +
  ggplot2::scale_color_manual(
    name = NULL,
    values = c(
      "winter" = "#961BFA",
      "summer" = "#FA9529",
      "transition" = "#0CC792"
    )
  ) +
  ggplot2::labs(
    title = "Dynamic vs. Static Values of Standard Load Profile 'H0'",
    subtitle = "96 x 1/4h measurements, based on consumption of 1,000 kWh/a",
    caption = "data: www.bdew.de"
  ) +
  ggplot2::theme_minimal() +
  ggplot2::theme(legend.position = "top") +
  ggplot2::theme(strip.text.y.right = ggplot2::element_text(angle = 0)) +
  ggplot2::theme(
    panel.grid.minor.x = ggplot2::element_blank(),
    panel.grid.minor.y = ggplot2::element_blank(),
    panel.grid = ggplot2::element_line(
      linetype = "12",
      lineend = "round",
      colour = "#FAF6F4"
    )
  ) +
  NULL

test_that("vignette example H0_dynamic works", {
  vdiffr::expect_doppelganger("vignette example 'H0_dynamic'", p4)
})
