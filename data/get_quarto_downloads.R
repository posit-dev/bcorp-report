library(here)
library(tidyverse)

source(here("data", "read_rstudio_downloads.R"))

# Quarto Downloads -------------------------------------------------------
#
# Writes `data/quarto_downloads.csv`, combining GitHub release download counts
# with the pre-1.4 downloads that were served from rstudio.com.

## Quarto downloads from when it was hosted on rstudio.com
quarto_rstudio_dls <-
  read_rstudio_downloads() |>
  filter(type %in% c("quarto")) |>
  mutate(
    source = "rstudio",
    version = str_extract(filename, "[01]\\.[0-9]\\.[0-9]+"),
    major_minor = str_extract(version, "[01]\\.[0-9]"),
  ) |>
  filter(date <= ymd("2024-01-24"))  # 1.4 release, served only from GitHub from this point forward

## Quarto downloads served from GitHub releases.
# Run helper script to generate `releases.csv`
# ./helpers/github_quarto.sh
releases <- read_csv(here("data", "releases.csv")) |>
  filter(!str_detect(name, "changelog"), !str_detect(name, "checksum")) |>
  rename(downloads = download_count, filename = name) |>
  mutate(
    date = date(created),
    version = str_extract(filename, "[01]\\.[0-9]+(\\.[0-9]+)?"),
    major_minor = str_extract(version, "[01]\\.[0-9]+"),
    source = "github"
  )

releases |>
  bind_rows(quarto_rstudio_dls) |>
  filter(! (major_minor %in% c("0.1", "0.2", "0.3"))) |>
  group_by(major_minor) |>
  summarise(
    downloads = sum(downloads),
    min_date = min(as.Date(date)),
    max_date = max(as.Date(date)),
    .groups = "drop"
  ) |>
  arrange(numeric_version(major_minor)) |>
  write_csv(here("data", "quarto_downloads.csv"))
