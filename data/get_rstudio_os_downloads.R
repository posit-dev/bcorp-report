library(here)
library(tidyverse)

source(here("data", "read_warehouse_downloads.R"))

# RStudio open-source / desktop downloads --------------------------------
#
# Writes `data/rstudio_os_downloads.csv`: daily downloads of open-source
# RStudio Desktop plus RStudio Server (open source), summed together.
#
# Downloads come from two sources, split at CUTOVER:
#   * Before CUTOVER - data/rstudio_downloads_legacy.csv, a committed daily
#     summary distilled from the (now frozen) internal downloads.csv feed by
#     helpers/summarise_downloads_csv.R.
#   * From CUTOVER on - per-month data-warehouse exports:
#       - Desktop  data/desktop-downloads/  (helpers/desktop_downloads_job.R)
#       - Server   data/server-downloads/   (helpers/rstudio_server_downloads_job.R)

# First day the warehouse exports take over from the legacy summary.
CUTOVER <- as.Date("2025-06-01")

## Legacy (pre-CUTOVER): desktop + open-source server, already daily by type.
legacy <- read_csv(
  here("data", "rstudio_downloads_legacy.csv"),
  show_col_types = FALSE
) |>
  filter(date < CUTOVER) |>
  select(date, downloads)

## Warehouse (from CUTOVER): desktop and open-source server exports. The server
## export is already filtered to open-source server at query time.
desktop_warehouse <- read_warehouse_downloads("desktop-downloads") |>
  filter(date >= CUTOVER) |>
  select(date, downloads)

server_warehouse <- read_warehouse_downloads("server-downloads") |>
  filter(date >= CUTOVER) |>
  select(date, downloads)

bind_rows(legacy, desktop_warehouse, server_warehouse) |>
  group_by(date) |>
  summarise(downloads = sum(downloads), .groups = "drop") |>
  write_csv(here("data", "rstudio_os_downloads.csv"))
