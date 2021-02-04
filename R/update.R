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


# create object containing existing api queries and publications
queries <- read.csv("data/api_queries.csv")
data <- read.csv("data/publications.csv")

# Init object to write api results into
api <- list()

# Run queries to identify new publications
if (NROW(queries$query) > 1) {
    api$ids <- unlist(
        lapply(
            X = queries$query,
            FUN = function(x) {
                pubmed$get_ids(query = x)
            }
        )
    )
} else {
    api$ids <- pubmed$get_ids(queries$query)
}

# remove existing IDs from api ID query list
api$ids <- api$ids[!api$ids %in% data$uid]

# fetch publication metadata (if there are new Ids)
if (length(api$ids)) {
    result <- pubmed$get_metadata(
        ids = api$ids,
        delay = sample(runif(50, 0.75, 2), length(api$ids))
    )

    # prepare publications dataset
    pubs <- pubmed$build_df(x = result)

    # save data
    write.csv(pubs, "data/test.csv", row.names = FALSE)
} else {
    message("no new publications")
}
