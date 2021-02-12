##////////////////////////////////////////////////////////////////////////////
## FILE: pubmed_api.R
## AUTHOR: David Ruvolo
## CREATED: 2021-01-20
## MODIFIED: 2021-02-05
## PURPOSE: source publications list from pubmed
## STATUS: working
## PACKAGES: *see DESCRIPTION*
## COMMENTS: NA
##////////////////////////////////////////////////////////////////////////////

# pubmed
# Methods for extacting pubmed data
pubmed <- structure(list(), class = "pubmed")

# get_ids
#
# In order to return publication metadata, you need to first retreive
# publication IDs. You can do this by building a query and using
# `get_ids`. Result is a character array.
pubmed$get_ids <- function(query) {

    response <- httr::GET(
        url = paste0(
            "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?",
            "db=pubmed",
            "&term=", utils::URLencode(query),
            "&retmode=json"
        ),
        httr::add_headers(
            `Content-Type` = "application/json"
        )
    )

    if (response$status_code == "200") {
        raw <- httr::content(response, "text", encoding = "UTF-8")
        raw %>%
            rjson::fromJSON(.) %>%
            `[[`("esearchresult") %>%
            `[[`("idlist")
    } else {
        stop(paste0("An error occurred: ", response$status_code))
    }
}

# get_metadata
#
# Using the list of publication IDs, you can now extract publication
# metadata. Pass the output of `get_ids`.
pubmed$get_metadata <- function(ids, delay = 0.5) {
    out <- data.frame()
    purrr::imap(ids, function(.x, .y) {
        response <- pubmed$make_request(.x)
        if (response$status_code == 200) {
            raw <- httr::content(response, as = "text", encoding = "UTF-8")
            result <- rjson::fromJSON(raw)
            df <- pubmed$clean_request(result)
            if (NROW(df) > 0) {
                message(paste0("  - Returned data for id: ", .x))
                if (.y == 1) {
                    out <<- df
                } else {
                    out <<- rbind(out, df)
                }
            } else {
                message(paste0("  - Nothing for id: ", .x))
            }
        } else {
            warning(paste0("Query failed:", response$status_code))
        }
        Sys.sleep(delay)
    })
    return(out)
}

# make_request
# Make a GET request for a single publication ID
pubmed$make_request <- function(id) {
    httr::GET(
        url = paste0(
            "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?",
            "db=pubmed",
            "&id=", id,
            "&retmode=json&"
        ),
        httr::add_headers(
            `Content-Type` = "application/json"
        )
    )
}

# clean_request
# Clean the result of `make_request`
pubmed$clean_request <- function(x) {
    id <- x[["result"]][["uids"]]
    data <- data.frame(
        uid = id,
        sortpubdate = x[["result"]][[id]][["sortpubdate"]],
        fulljournalname = x[["result"]][[id]][["fulljournalname"]],
        volume = x[["result"]][[id]][["volume"]],
        elocationId = x[["result"]][[id]][["elocationid"]],
        title = x[["result"]][[id]][["title"]]
    )
    data$authors <- paste0(
        sapply(
            x[["result"]][[id]][["authors"]],
            function(n) {
                n[["name"]]
            }
        ),
        collapse = "; "
    )
    return(data)
}

# build_df
# Compile results from `get_metadata` into a tidy object
pubmed$build_df <- function(data) {
    d <- data
    d$uid <- as.character(d$uid)
    d$sortpubdate <- as.Date(lubridate::ymd_hm(d$sortpubdate))
    d$doi_url <- stringr::str_replace_all(
        string = d$elocationId,
        pattern = "doi: ",
        replacement = "https://doi.org/"
    )
    d$doi_label <- stringr::str_replace_all(
        string = d$elocationId,
        pattern = "doi: ",
        replacement = ""
    )
    d$elocationId <- NULL
    d <- d[order(d$sortpubdate, decreasing = TRUE), ]
    d$sortpubdate <- as.character(d$sortpubdate)
    return(d)
}