library(here)
library(tidyverse)

source(here("data", "read_rstudio_downloads.R"))

# RStudio open-source / desktop downloads --------------------------------
#
# Writes `data/rstudio_os_downloads.csv`: daily downloads of open-source
# RStudio Desktop plus RStudio Server (open source), summed together.
#
# For both desktop and server, downloads come from the legacy downloads.csv
# feed before CUTOVER and from a per-month data-warehouse export from CUTOVER
# onward (the downloads.csv feed stopped updating in early 2026):
#   * Desktop  - data/desktop-downloads/  (helpers/desktop_downloads_job.R)
#   * Server   - data/server-downloads/   (helpers/rstudio_server_downloads_job.R)

# First day the warehouse exports replace the legacy downloads.csv feed.
CUTOVER <- as.Date("2025-06-01")

rstudio_dls <- read_rstudio_downloads()

## Desktop: legacy feed before the cutover, warehouse export from cutover on.
desktop_legacy <- rstudio_dls |>
  filter(type == "desktop", date < CUTOVER) |>
  select(date, downloads)

desktop_warehouse <- read_warehouse_downloads("desktop-downloads") |>
  filter(date >= CUTOVER) |>
  select(date, downloads)

## Server (open source): legacy feed before the cutover, warehouse from cutover.
## The warehouse export is already filtered to open-source server at query time.
server_legacy <- rstudio_dls |>
  filter(type == "RS-os", date < CUTOVER) |>
  select(date, downloads)

server_warehouse <- read_warehouse_downloads("server-downloads") |>
  filter(date >= CUTOVER) |>
  select(date, downloads)

bind_rows(desktop_legacy, desktop_warehouse, server_legacy, server_warehouse) |>
  group_by(date) |>
  summarise(downloads = sum(downloads), .groups = "drop") |>
  write_csv(here("data", "rstudio_os_downloads.csv"))
