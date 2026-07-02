library(here)
library(bigrquery)
library(tidyverse)

# Python Package Downloads -----------------------------------------------
#
# Writes `data/python_package_downloads.csv`.

# https://packaging.python.org/en/latest/guides/analyzing-pypi-package-downloads/
# Set up new Google Big Query project: `pypi-downloads-458318`
billing <- "pypi-downloads-458318"

python_packages <- c(
  "great-tables",
  "shiny",
  "vetiver",
  "pins",
  "plotnine",
  "siuba"
)
packages_sql <- paste0("'", paste(python_packages, collapse = "','"), "'")

mirrors <- c("bandersnatch", "z3c.pypimirror", "Artifactory", "devpi")
mirrors_sql <- paste0("'", paste(mirrors, collapse = "','"), "'")

existing_python_downloads <- read_csv(
  here("data", "python_package_downloads.csv")
)
start_date <- max(existing_python_downloads$date) + 1

sql <- sprintf(
  "
SELECT
    COUNT(*) AS downloads,
    DATE(timestamp) AS `date`,
    file.project AS package
FROM `bigquery-public-data.pypi.file_downloads`
WHERE
      file.project IN (%s)
      AND timestamp >= TIMESTAMP('%s')
      AND timestamp <  TIMESTAMP('%s')
      AND details.installer.name NOT IN (%s)
GROUP BY `date`, file.project
ORDER BY `date`",
  packages_sql,
  start_date,
  Sys.Date(),
  mirrors_sql
)

# Inspect bytes to be scanned before running:
# bq_perform_query_dry_run(sql, billing = billing)

tb <- bq_project_query(billing, sql)
new_python_downloads <- bq_table_download(tb)

bind_rows(existing_python_downloads, new_python_downloads) |>
  distinct(package, date, .keep_all = TRUE) |>
  arrange(package, date) |>
  write_csv(here("data", "python_package_downloads.csv"))
