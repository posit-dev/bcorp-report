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


#----RStudio downloads

