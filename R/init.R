#'////////////////////////////////////////////////////////////////////////////
#' FILE: init.R
#' AUTHOR: David Ruvolo
#' CREATED: 2021-02-04
#' MODIFIED: 2021-02-04
#' PURPOSE: init publications for the first time
#' STATUS: in.progress
#' PACKAGES: see below and in `R/pubmed.R`
#' COMMENTS: NA
#'////////////////////////////////////////////////////////////////////////////

#' pkgs
suppressPackageStartupMessages(library(dplyr))

#' source utils
source("R/pubmed.R")

#' api output object - using my name as an example
api <- list(
    query = data.frame(
        id = "q_01",
        type = "author",
        query = "Ruvolo, David[Author]"
    )
)

#' get Ids via query
api$ids <- pubmed$get_ids(api$query$query)

#' fetch publications
results <- pubmed$get_metadata(
    ids = api$ids,
    delay = sample(runif(50, 0.75, 2), length(api$ids))
)

final <- pubmed$build_df(results)

#' write data
write.csv(api$query, "data/api_queries.csv", row.names = FALSE)
write.csv(final[2, ], "data/publications.csv", row.names = FALSE)
