library(here)
library(tidyverse)

# Read and classify the internal RStudio/Quarto downloads feed.
#
# Reads `data/downloads.csv` (an unheaded export of the RStudio metrics feed,
# originally from https://www.rstudio.org/internal/metrics/downloads.csv.gz),
# keeps downloads from 2017 onward, and tags each row with a product `type`.
# Returns a tibble with columns: filename, date, downloads, type.
#
# NOTE: downloads.csv (~755MB, gitignored) is no longer on the pipeline's
# primary path. It froze in early 2026 and has been distilled into small,
# committed summaries (rstudio_downloads_legacy.csv, quarto_downloads_legacy.csv)
# that the get_*.R scripts read instead. This reader is kept for, and used only
# by, helpers/summarise_downloads_csv.R (which regenerates those summaries) and
# helpers/rstudio-downloads.qmd (the warehouse-vs-internal-metrics validation).
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
