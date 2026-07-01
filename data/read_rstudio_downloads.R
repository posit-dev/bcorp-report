library(here)
library(tidyverse)

# Read the per-month warehouse download exports from data/<dir>/ and bind them
# into one tibble (columns: date, filename, downloads). These are produced by
# helpers/desktop_downloads_job.R (and, later, the equivalent server job) from
# the data warehouse, and replace the internal downloads.csv feed from
# mid-2025 onward. Rows are not re-classified: each export folder is a single
# product (e.g. desktop-downloads/ is RStudio Desktop).
read_warehouse_downloads <- function(dir) {
  fs::dir_ls(here("data", dir), glob = "*.csv") |>
    map(read_csv, show_col_types = FALSE) |>
    list_rbind()
}

# Read and classify the internal RStudio/Quarto downloads feed.
#
# Reads `data/downloads.csv` (an unheaded export of the RStudio metrics feed,
# originally from https://www.rstudio.org/internal/metrics/downloads.csv.gz),
# keeps downloads from 2017 onward, and tags each row with a product `type`.
#
# Returns a tibble with columns: filename, date, downloads, type.
# Shared by get_rstudio_os_downloads.R and get_quarto_downloads.R, both of
# which slice this classified data differently.
read_rstudio_downloads <- function() {
  read_csv(
    here("data", "downloads.csv"),
    col_names = c("filename", "date", "downloads")
  ) |>
    filter(date >= ymd("2017-01-01")) |>
    mutate(
      type = case_when(
        str_detect(filename, "docs|admin-guide") ~ "docs",
        str_detect(filename, "-monitor-") ~ "monitor",
        str_detect(filename, "rstudio-server-pro") ~ "RSP",
        str_detect(filename, "rstudio-server") ~ "RS-os",
        str_detect(filename, "rstudio-connect") ~ "RSC",
        str_detect(filename, "shiny-server-commercial") ~ "SSP",
        str_detect(filename, "shiny-server") ~ "SS-os",
        str_detect(filename, "rstudio-pm") ~ "RSPM",
        str_detect(filename, regex("^rstudio-", ignore_case = TRUE)) ~ "desktop",
        str_detect(filename, "^desktop") ~ "desktop",
        #RZ additions
        str_detect(filename, "electron") ~ "desktop",
        str_detect(filename, "quarto-") ~ "quarto"
      )
    )
}
