library(googledrive)
library(rmarkdown)
library(here)

# drive_find(n_max = 30)

pbc_report_id <- as_id("1TtaUqTliMeMsl3NicEfVYnYE2eYeWWkU5SpXXwuaTmI")
local_path <- here("import", "raw-report.docx")
drive_download(pbc_report_id, path = local_path, overwrite = TRUE)

pandoc_convert(
  local_path, 
  to = "markdown",
  output = here("import", "raw-report.md")
)
