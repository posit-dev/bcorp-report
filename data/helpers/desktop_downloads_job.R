#!/usr/bin/env Rscript

# Computes daily RStudio Desktop download counts from the data
# warehouse, one month at a time, writing each month to its own CSV as it goes.
#
# "downloads" = count of HTTP 200 responses per installer file per UTC day on
# aws_logs_rs.download1_rstudio_org. 
#
# Designed to run non-interactively as a Posit Workbench job. Progress is saved
# per month, so the job is resumable: re-running skips months already written
# (unless OVERWRITE = TRUE).

# ---- Configuration ----------------------------------------------------------

START_DATE <- as.Date("2025-06-01")
END_DATE   <- Sys.Date()
# Anchored to the repo root so it lands in the gitignored data/desktop-downloads/
# regardless of the job's working directory. NOTE: hyphen, to match .gitignore.
OUTPUT_DIR <- here::here("data", "desktop-downloads")  # one CSV per month is written here
OVERWRITE  <- FALSE                   # TRUE to recompute months already saved

# -----------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(here)
  library(warehouse)
  library(dbplyr)
  library(dplyr)
  library(stringr)
  library(readr)
})

INSTALLER_EXT <- c(".exe", ".dmg", ".deb", ".rpm", ".zip", ".gz")

log_msg <- function(...) {
  message(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "  ", sprintf(...))
}

# Candidate B for a UTC date range: one row per (date, filename) with the count
# of HTTP 200 responses. Filters on the year/month/day partition columns (via a
# YYYYMMDD key) so only the requested day partitions are scanned.
desktop_downloads <- function(con, start_date, end_date) {
  ymd_keys <- format(seq(as.Date(start_date), as.Date(end_date), by = "day"), "%Y%m%d")

  tbl(con, in_schema("aws_logs_rs", "download1_rstudio_org")) |>
    filter(
      paste0(year, month, day) %in% ymd_keys,
      status == 200L,
      tolower(sql("regexp_substr(uri, '\\.[A-Za-z0-9]+$')")) %in% INSTALLER_EXT
    ) |>
    group_by(year, month, day, uri) |>
    summarise(downloads = n(), .groups = "drop") |>
    collect() |>
    transmute(
      date = as.Date(paste(year, month, day, sep = "-")),
      filename = str_remove(uri, "^/"),   # match legacy filename convention
      downloads = as.numeric(downloads)
    ) |>
    arrange(date, filename)
}

last_day_of_month <- function(d) {
  seq(as.Date(format(d, "%Y-%m-01")), by = "month", length.out = 2)[2] - 1
}

# ---- Run --------------------------------------------------------------------

if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

log_msg("Connecting to the lakehouse ...")
dw_con <- lakehouse()
on.exit(try(DBI::dbDisconnect(dw_con), silent = TRUE), add = TRUE)

month_starts <- seq(as.Date(format(START_DATE, "%Y-%m-01")), END_DATE, by = "month")
log_msg("Processing %d month(s): %s to %s",
        length(month_starts), format(START_DATE), format(END_DATE))

results <- data.frame(month = character(), rows = integer(),
                      downloads = numeric(), seconds = numeric(),
                      status = character(), stringsAsFactors = FALSE)

for (ms in month_starts) {
  ms      <- as.Date(ms, origin = "1970-01-01")
  m_start <- max(ms, START_DATE)
  m_end   <- min(last_day_of_month(ms), END_DATE)
  tag     <- format(ms, "%Y-%m")
  outfile <- file.path(OUTPUT_DIR, sprintf("desktop_downloads_%s.csv", tag))

  if (file.exists(outfile) && !OVERWRITE) {
    log_msg("[%s] skip (already exists: %s)", tag, outfile)
    results <- rbind(results, data.frame(month = tag, rows = NA_integer_,
      downloads = NA_real_, seconds = 0, status = "skipped"))
    next
  }

  log_msg("[%s] computing %s to %s ...", tag, format(m_start), format(m_end))
  t0 <- Sys.time()

  month_df <- tryCatch(
    desktop_downloads(dw_con, m_start, m_end),
    error = function(e) {
      log_msg("[%s] ERROR: %s", tag, conditionMessage(e))
      NULL
    }
  )

  if (is.null(month_df)) {
    results <- rbind(results, data.frame(month = tag, rows = NA_integer_,
      downloads = NA_real_, seconds = NA_real_, status = "error"))
    next
  }

  write_csv(month_df, outfile)
  secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  log_msg("[%s] wrote %d rows (%s downloads) in %.0fs -> %s",
          tag, nrow(month_df), format(sum(month_df$downloads), big.mark = ","),
          secs, outfile)
  results <- rbind(results, data.frame(month = tag, rows = nrow(month_df),
    downloads = sum(month_df$downloads), seconds = round(secs), status = "ok"))
}

log_msg("Done. Summary:")
print(results, row.names = FALSE)

n_err <- sum(results$status == "error")
if (n_err > 0) {
  log_msg("%d month(s) failed; re-run to retry (successful months are skipped).", n_err)
  quit(status = 1)
}
