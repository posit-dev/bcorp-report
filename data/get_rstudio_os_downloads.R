library(here)
library(tidyverse)

source(here("data", "read_rstudio_downloads.R"))

# RStudio open-source / desktop downloads --------------------------------
#
# Writes `data/rstudio_os_downloads.csv`.

rstudio_dls <- read_rstudio_downloads()

## Just keep open-source/desktop rstudio dls.
rstudio_open_source_downloads <- rstudio_dls |>
  filter(type %in% c("RS-os", "desktop"))

rstudio_open_source_downloads |>
  group_by(date) |>
  summarise(downloads = sum(downloads)) |>
  write_csv(here("data", "rstudio_os_downloads.csv"))
