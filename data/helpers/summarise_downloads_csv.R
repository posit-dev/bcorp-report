#!/usr/bin/env Rscript

# Distil the internal RStudio metrics feed (data/downloads.csv, ~755MB,
# gitignored) into small, committable daily summaries that the pipeline reads
# instead of the raw file.
#
# downloads.csv was the original source for RStudio downloads and for the
# pre-1.4 Quarto downloads that were served from rstudio.com. It is too large
# for version control and has been frozen since 2026-02-20 (RStudio downloads
# now come from the data warehouse; see get_rstudio_os_downloads.R). This
# script writes:
#
#   data/rstudio_downloads_legacy.csv  - date, type, downloads
#                                        (desktop + open-source server)
#   data/quarto_downloads_legacy.csv   - date, downloads, major_minor
#                                        (Quarto served from rstudio.com, pre-1.4)
#
# Because the feed is frozen these summaries should not need regenerating; this
# script is kept to document how downloads.csv was processed and to rebuild the
# summaries if the raw file is ever refreshed. Run from anywhere:
#   Rscript data/helpers/summarise_downloads_csv.R

library(here)
library(tidyverse)

source(here("data", "read_rstudio_downloads.R"))

rstudio_dls <- read_rstudio_downloads()

# RStudio: daily desktop + open-source server downloads. Kept split by product
# so the full history stays symmetric with the desktop/server warehouse feeds.
rstudio_dls |>
  filter(type %in% c("desktop", "RS-os")) |>
  group_by(date, type) |>
  summarise(downloads = sum(downloads), .groups = "drop") |>
  arrange(date, type) |>
  write_csv(here("data", "rstudio_downloads_legacy.csv"))

# Quarto: daily downloads served from rstudio.com, up to the 1.4 release
# (2024-01-24), after which Quarto was served only from GitHub.
rstudio_dls |>
  filter(type == "quarto") |>
  mutate(
    version = str_extract(filename, "[01]\\.[0-9]\\.[0-9]+"),
    major_minor = str_extract(version, "[01]\\.[0-9]"),
  ) |>
  filter(date <= ymd("2024-01-24")) |>
  group_by(date, major_minor) |>
  summarise(downloads = sum(downloads), .groups = "drop") |>
  arrange(date, major_minor) |>
  write_csv(here("data", "quarto_downloads_legacy.csv"))
