library(here)
library(tidyverse)

# Read the per-month warehouse download exports from data/<dir>/ and bind them
# into one tibble (columns: date, filename, downloads). These are produced by
# helpers/desktop_downloads_job.R and helpers/rstudio_server_downloads_job.R
# from the data warehouse, and are the source for RStudio downloads from
# 2025-06 onward. Rows are not re-classified: each export folder is a single
# product (e.g. desktop-downloads/ is RStudio Desktop).
read_warehouse_downloads <- function(dir) {
  fs::dir_ls(here("data", dir), glob = "*.csv") |>
    map(read_csv, show_col_types = FALSE) |>
    list_rbind()
}
