library(here)
library(cranlogs)
library(gh)
library(tidyverse)
library(tidymodels)

# R Package Downloads ------------------------------------------------------
#
# Writes `data/r_package_downloads.csv`.

tidyverse <- tibble(
  package = tidyverse_packages(FALSE),
  project = "tidyverse"
)

tidymodels <- tibble(
  package = tidymodels_packages(FALSE),
  project = "tidymodels"
)

repos_json <- gh::gh("/orgs/{org}/repos", org = "r-lib", .limit = Inf)
names <- sapply(repos_json, "[[", "name")
rlib_repos <- intersect(names, rownames(available.packages()))

rlib <- tibble(
  package = rlib_repos,
  project = "r-lib"
)

connectivity <- tibble(
  package = c("sparklyr", "tensorflow", "keras", "odbc", "reticulate"),
  project = "connectivity"
)

r_packages <-
  tibble(
    package = c("shiny", "gt", "vetiver", "pins", "webR"),
    project = c("shiny", "gt", "vetiver", "pins", "webR"),
  ) |>
  bind_rows(
    tidyverse,
    tidymodels,
    rlib,
    connectivity
  )

existing_r_downloads <- read_csv(here("data", "r_package_downloads.csv"))

# Per-package start date: day after each package's last recorded date,
# or 2017-01-01 for packages new to the list.
max_dates <- existing_r_downloads |>
  group_by(package) |>
  summarise(max_date = max(date), .groups = "drop")

r_packages_with_start <- r_packages |>
  left_join(max_dates, by = "package") |>
  mutate(
    start_date = if_else(is.na(max_date), as.Date("2017-01-01"), max_date + 1)
  )

new_r_downloads <- r_packages_with_start |>
  rowwise() |>
  mutate(
    downloads = list(cran_downloads(package, from = as.character(start_date)))
  )  |>
  ungroup() |>
  unnest(downloads, names_sep = "_") |>
  select(package, project, date = downloads_date, downloads = downloads_count)

bind_rows(existing_r_downloads, new_r_downloads) |>
  distinct(package, project, date, .keep_all = TRUE) |>
  arrange(package, date) |>
  write_csv(here("data", "r_package_downloads.csv"))
