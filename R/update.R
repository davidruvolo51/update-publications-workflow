##////////////////////////////////////////////////////////////////////////////
## FILE: update.R
## AUTHOR: David Ruvolo
## CREATED: 2021-02-04
## MODIFIED: 2021-02-05
## PURPOSE: entry point for GitHub Action
## STATUS: working
## PACKAGES: see below and in `R/pubmed.R`
## COMMENTS: NA
##////////////////////////////////////////////////////////////////////////////

suppressPackageStartupMessages(library(dplyr))

# create object containing existing api queries and publications
message("Loading reference datasets:")
queries <- tryCatch({
    message("  - API queries: success!")
    # read.csv("data/api_queries.csv")
    read.csv("https://raw.githubusercontent.com/davidruvolo51/update-publications-workflow/main/data/api_queries.csv")
}, error = function(error) {
    warning("Unable to load reference datasets")
}, warning = function(warn) {
    warning("Unable to load reference datasets")
})

data <- tryCatch({
    message("  - publications: complete!")
    # read.csv("data/publications.csv")
    read.csv("https://raw.githubusercontent.com/davidruvolo51/update-publications-workflow/main/data/publications.csv")
}, error = function(error) {
    warning("  - publications: failed (error)")
    return(FALSE)
}, warning = function(warn) {
    warning("  - publications: failed (warning)")
    return(FALSE)
})

# check reference datasets
if (isFALSE(data)) warning("Failed to import 'queries.csv'")
if (isFALSE(queries)) warning("Failed to import 'publications.csv'")

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
message("Removing existing IDs using reference data: ")
api$ids <- api$ids[!api$ids %in% data$uid]

message(paste0("  - Total IDs to query: ", length(api$ids)))

# fetch publication metadata (if there are new Ids)
if (length(api$ids)) {
    message("Pulling Metadata for new IDs: ")
    result <- pubmed$get_metadata(
        ids = api$ids,
        delay = sample(runif(50, 0.75, 2), length(api$ids))
    )

    # prepare publications dataset
    pubs <- pubmed$build_df(data = result)
    message(paste0("Processed data dimensions: ", paste0(dim(pubs), collapse = ", ")))

    # save data
    message("Saving data...")
    write.csv(rbind(data, pubs), "data/publications.csv", row.names = FALSE)
} else {
    message("No new publications! :-)")
}
