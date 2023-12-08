
# example #1 --------------------------------------------------------------

# labeler
label_names <- c(
  "saturday"="Saturday",
  'sunday'="Sunday",
  'workday'="Workday"
)

label_fun <- function(x) label_names[[x]]

# reorder facets
slp$day <- factor(slp$day, levels = c("workday", "saturday", "sunday"))

# plot
p1 <- ggplot2::ggplot(slp,
                      ggplot2::aes(x = as.POSIXct(x = paste(Sys.Date(), timestamp)),
                                   y = watts,
                                   color = period)) +
  ggplot2::geom_line() +
  ggplot2::facet_grid(profile_id ~ day, scales = "free_y",
             labeller = ggplot2::labeller(day = ggplot2::as_labeller(label_names))) +
  ggplot2::scale_x_datetime(NULL, date_labels = "%k:%M") +
  ggplot2::scale_y_continuous(NULL) +
  ggplot2::scale_color_manual(name = NULL,
                     values = c(
                       "winter" = "#961BFA",
                       "summer" = "#FA9529",
                       "transition" = "#0CC792"
                     )) +
  ggplot2::labs(title = "Standard Load Profiles",
       subtitle = "96 x 1/4h measurements each day [in watts], based on consumption of 1,000 kWh/a",
       caption = "data: www.bdew.de") +
  ggplot2::theme_minimal() +
  ggplot2::theme(legend.position = "top") +
  ggplot2::theme(strip.text.y.right = ggplot2::element_text(angle = 0)) +
  ggplot2::theme(
    panel.grid.major.x = ggplot2::element_blank(),
    panel.grid.major.y = ggplot2::element_blank(),
    panel.grid.minor.y = ggplot2::element_blank(),
    panel.grid = ggplot2::element_line(
      linetype = "12",
      lineend = "round",
      colour = "#FAF6F4"
    )
  ) +
  NULL


test_that("readme example #1 works", {
  vdiffr::expect_doppelganger("readme example 'small multiples'", p1)
})


# example #2 --------------------------------------------------------------
G5 <- slp_generate(profile_id = "G5",
                   start_date = "2023-12-22",
                   end_date = "2023-12-27")

p2 <- ggplot2::ggplot(G5, ggplot2::aes(start_time, watts)) +
  ggplot2::geom_line(color = "#0CC792") +
  ggplot2::scale_x_datetime(date_breaks = "1 day", date_labels = "%b %d") +
  ggplot2::labs(title = "'G5': bakery with bakehouse",
                subtitle = "1/4h measurements, based on consumption of 1,000 kWh/a",
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

test_that("readme example #2 works", {
  vdiffr::expect_doppelganger("readme example 'G5'", p2)
})
