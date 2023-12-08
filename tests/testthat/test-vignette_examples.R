H0_2024 <- slp_generate(
  profile_id = "H0",
  start_date = "2024-01-01",
  end_date = "2024-12-31"
)

# aggregate by day of year as decimal number (1 - 365)
H0_2024_daily <- by(H0_2024, INDICES = format(H0_2024$start_time, "%j"), FUN = function(x) {
  data.frame(
    start_time = x[["start_time"]][1],
    watts = mean(x[["watts"]])
  )
})
H0_2024_daily <- do.call(rbind, args = H0_2024_daily)

# example -----------------------------------------------------------------
p3 <- ggplot2::ggplot(H0_2024_daily, ggplot2::aes(start_time, watts)) +
  ggplot2::geom_line(color = "#0CC792") +
  ggplot2::labs(title = "Profile 'H0': Households",
       subtitle = "Electrical power per day",
       caption = "data: www.bdew.de",
       x = NULL,
       y = "[watts]") +
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
  vdiffr::expect_doppelganger("vignetee example 'H0'", p3)
})
