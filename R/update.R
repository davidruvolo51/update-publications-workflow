##////////////////////////////////////////////////////////////////////////////
## FILE: update.R
## AUTHOR: David Ruvolo
## CREATED: 2021-02-04
## MODIFIED: 2021-02-04
## PURPOSE: entry point for GitHub Action
## STATUS: in.progress
## PACKAGES: see below and in `R/pubmed.R`
## COMMENTS: NA
##////////////////////////////////////////////////////////////////////////////

suppressPackageStartupMessages(library(dplyr))

# create object containing existing api queries and publications
queries <- data.frame()
data <- data.frame()
tryCatch({
    message("Loaded reference datasets\n\t- API queries\n\t- publications")
    queries <<- read.csv("https://raw.githubusercontent.com/davidruvolo51/update-publications-workflow/main/data/api_queries.csv")
    data <<- read.csv("https://raw.githubusercontent.com/davidruvolo51/update-publications-workflow/main/data/publications.csv")
}, error = function(error) {
    warning("Unable to load reference datasets")
}, warning = function(warn) {
    warning("Unable to load reference datasets")
})

# Init object to write api results into
api <- list()

# Run queries to identify new publications
message("Processing publication queries:")
if (NROW(queries$query) > 1) {
    message("\t- binding multiple queries into an array")
    api$ids <- unlist(
        lapply(
            X = queries$query,
            FUN = function(x) {
                pubmed$get_ids(query = x)
            }
        )
    )
} else {
    message("\t- fetching IDs using one query")
    api$ids <- pubmed$get_ids(queries$query)
}

# remove existing IDs from api ID query list
message("Removing existing IDs using reference data")
api$ids <- api$ids[!api$ids %in% data$uid]

# fetch publication metadata (if there are new Ids)
if (length(api$ids)) {
    message(paste0("Pulling Metadata for new IDs: ", api$ids))
    result <- pubmed$get_metadata(
        ids = api$ids,
        delay = sample(runif(50, 0.75, 2), length(api$ids))
    )

    # prepare publications dataset
    pubs <- pubmed$build_df(data = result)
    message(paste0("Returned data dims:", dims(pubs)))

    # save data
    message("Saving new publications!")
    write.csv(pubs, "data/test.csv", row.names = FALSE)
} else {
    message("No new publications")
}
