#'////////////////////////////////////////////////////////////////////////////
#' FILE: dev.R
#' AUTHOR: David Ruvolo
#' CREATED: 2021-02-04
#' MODIFIED: 2021-02-05
#' PURPOSE: pkg management
#' STATUS: working
#' PACKAGES: NA
#' COMMENTS: NA
#'////////////////////////////////////////////////////////////////////////////

#' init project
usethis::create_project(path = ".")
usethis::use_description(check_name = FALSE)
usethis::use_namespace()

#' pkgs
usethis::use_package("dplyr")
usethis::use_package("httr")
usethis::use_package("rjson")
usethis::use_package("purrr")
usethis::use_package("stringr")
usethis::use_package("lubridate")