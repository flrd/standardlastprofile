# attach packages ---------------------------------------------------------
library(readxl)
library(data.table)

# https://stackoverflow.com/questions/31589170/download-unzip-and-load-excel-file-in-r-using-tempfiles-only

# load data ---------------------------------------------------------------

path <- "~/Downloads/Profile/Repr„sentative Profile VDEW.xls"
sheets <- readxl::excel_sheets(path)
n_sheets <- length(sheets)

# create empty list of length = n_sheets
output <- vector(mode = "list", length = n_sheets)

# populate list
for (i in seq_len(n_sheets)) {
  output[[i]] <- readxl::read_excel(
    sheet = sheets[i],
    path,
    range = "A3:J99",
    col_types = c(
      "date",
      "numeric",
      "numeric",
      "numeric",
      "numeric",
      "numeric",
      "numeric",
      "numeric",
      "numeric",
      "numeric"
    )
  )
}
names(output) <- sheets

# data clean-up -----------------------------------------------------------

# update names
days <- c("saturday", "sunday", "workingDay")
periods <- c("winter", "summer", "transition")
nms <- c("timestamp", rep(periods, each = 3))

tmp <- lapply(output, function(profile) {
  setDT(profile)

  # rename columns
  setnames(profile, c(nms[1], paste(days, nms[-1], sep = "_")))

  # remove date part from 'timestamp' column
  profile[, timestamp := format(profile$timestamp, "%H:%M")]

})

VDEW_profiles_long <- lapply(tmp, function(profile) {

  # reshape from wide to long format
  profile <- melt(profile, measure.vars = patterns(days), value.name = days)

  # name values in column 'type' to appropriate period
  profile[, periods := `levels<-`(variable, periods)]

  # remove column 'variable'
  profile[, variable := NULL]

  return(profile)
})

VDEW_profiles_long <- data.table::rbindlist(VDEW_profiles_long, idcol = "profile")


usethis::use_data(load_profiles, overwrite = TRUE)



