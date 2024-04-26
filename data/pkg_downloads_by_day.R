library(httr)
library(dplyr)
library(cranlogs)
source("github_extract.R")


#pypistats provides API endpoint for packages, remove mirrors from dataset
get_pypi_daily_downloads <- function(pkg) {
  
  r <- GET(sprintf("https://pypistats.org/api/packages/%s/overall?mirrors=false", pkg))
  df <- bind_rows(content(r)$data)
  df$category <- NULL
  df$pkg <- pkg

  return(df)

}

#python packages for b-corp report
pkgs <- c("great_tables", "shiny", "vetiver", "plotnine", "siuba")
pydf <- bind_rows(lapply(pkgs, get_pypi_daily_downloads))

#write.csv(pydf, "pypi_stats.csv", row.names = FALSE)

#---

#r packages for b-corp report
rpkgs <- cran_downloads(c("shiny", "gt", "vetiver", "webR"),
                        from = "2017-01-01")

#write.csv(rpkgs, "rpkgs.csv", row.names = FALSE)

#tidyverse packages
tidyvpkgs <- cran_downloads(tidyverse_packages(FALSE), from = "2017-01-01")
#write.csv(tidyvpkgs, "tidyverse_pkgs.csv", row.names = FALSE)

#tidymodels packages - need to validate with Max, don't seem to be accounting for 42 packages as he does
tidympkgs <-  cran_downloads(tidymodels_packages(FALSE), from = "2017-01-01")
#write.csv(tidympkgs, "tidymodels_pkgs.csv", row.names = FALSE)


#r-lib packages
rlib_repos <- repo_list("r-lib") %>% table_format()

#notcran list found through trial and error, shouldn't expect this to stay constant over time
notcran <- c("r-azure-pipelines", "r-lib.github.io", "repository-dispatch", "tree-sitter-r", "homebrew-taps", "homebrew-rig", "r-svn")
cran_downloads(setdiff(rlib_repos$name, notcran), from = "2017-01-01") %>% 
  bind_rows() -> rlib_data
#write.csv(rlib_data, "rlib_pkgs.csv", row.names = FALSE)

#r connectivity
rcondf <- cran_downloads(c("sparklyr", "tensorflow", "keras", "odbc", "reticulate"), from = "2017-01-01")
#write.csv(rcondf, "rcon_pkgs.csv", row.names = FALSE)


#----RStudio and Quarto downloads
#RZ: not adding all the boilerplate to do this from the code, downloaded via browser
#not committing file to git due to size
#code originally came from Garrett for 2021 report, but simplifying it greatly here
#DOWNLOAD_URL <- "https://www.rstudio.org/internal/metrics/downloads.csv.gz"

rstudio_dls <- read.csv("downloads.csv.gz", header = FALSE, col.names = c("filename", "date", "downloads"))  %>% 
  filter(date >= ymd("2017-01-01"))

rstudio_dls <- rstudio_dls %>% mutate(
  type = case_when(
    str_detect(filename, "docs|admin-guide") ~ "docs",
    str_detect(filename, "-monitor-") ~ "monitor",
    
    str_detect(filename, "rstudio-server-pro")  ~ "RSP",
    str_detect(filename, "rstudio-server")  ~ "RS-os",
    str_detect(filename, "rstudio-connect")  ~ "RSC",
    str_detect(filename, "shiny-server-commercial") ~ "SSP",
    str_detect(filename, "shiny-server") ~ "SS-os",
    str_detect(filename, "rstudio-pm") ~ "RSPM",
    str_detect(filename, regex("^rstudio-", ignore_case = TRUE)) ~ "desktop",
    str_detect(filename, "^desktop") ~ "desktop",
    #RZ additions
    str_detect(filename, "electron") ~ "desktop"
  )
)

## Just keep open-source/desktop rstudio dls.
rstudio_open_source_downloads <- rstudio_dls %>% filter(type %in% c("RS-os", "desktop"))
rstudio_open_source_downloads %>%
  group_by(date) %>%
  summarise(downloads = sum(downloads)) -> rsdf
write.csv(rsdf, "rstudio_os_dls.csv", row.names = FALSE)
