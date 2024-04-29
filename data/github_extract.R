library(gh)
library(tidyverse)
library(purrr)

#### Helper functions ####

# Given the json, just pull out the login information 
parse_members_list <- function(json) {
  json %>% 
    map_chr("login") %>% 
    sort()
}

# Extract the members list from Github
members_list <- function(org) {
  gh("GET /orgs/:org/members",
     org = org,
     .limit = Inf)
}

# Given an organization, return al the repos
repo_list <- function(org) {
  gh("GET /orgs/:org/repos",
     org = org,
     .limit = Inf)
}

# convenience function to turn the results into a data frame
table_format <- function(json) {
  tibble(json = unclass(json)) %>% 
    unnest_wider(json)
}

extract_all_repos <- function() {
  tidyverse_repos <- repo_list("tidyverse") %>% table_format()
  
  rlib_repos <- repo_list("r-lib") %>% table_format()
  
  tidymodels_repos <- repo_list("tidymodels") %>% table_format()
  
  rstudio_repos <- repo_list("rstudio") %>% table_format()
  
  rdbi_repos <- repo_list("r-dbi") %>% table_format()
  
  ## This is not working for some reason.
  # yihui_repos <- repo_list("yihui") %>% table_format()
  
  ## Ursa
  # ursa_repos <- repo_list("apache/arrow") %>% table_format()
  
  all_repos <- dplyr::bind_rows(tidyverse_repos, rlib_repos, tidymodels_repos, rstudio_repos, rdbi_repos)
  
  write_report(all_repos, "all_repos.rds")
}



# rstudio_members_json <- members_list("rstudio")
# 
# rstudio_members <- parse_members_list(rstudio_members_json)
# 
# tidyverse_members_json <- members_list("tidyverse") 
# 
# tidyverse_members <- parse_members_list(tidyverse_members_json)
# 
# rlib_members_json <- members_list("r-lib") 
# 
# rlib_members <- parse_members_list(rlib_members_json)
