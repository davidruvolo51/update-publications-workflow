##////////////////////////////////////////////////////////////////////////////
## FILE: pubmed_api.R
## AUTHOR: David Ruvolo
## CREATED: 2021-01-20
## MODIFIED: 2021-01-21
## PURPOSE: source publications list from pubmed
## STATUS: in.progress
## PACKAGES: *see below*
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
    for (n in seq_len(length(ids))) {
        response <- pubmed$make_request(ids[n])
        if (response$status_code == 200) {
            raw <- httr::content(response, as = "text", encoding = "UTF-8")
            result <- rjson::fromJSON(raw)
            df <- pubmed$clean_request(result)
            if (NROW(df) > 0) {
                out <<- rbind(out, df)
            }
        } else {
            warning(paste0("Query failed:", response$status_code))
        }
        Sys.sleep(delay)
    }
    out
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
    data.frame(
        uid = id,
        sortpubdate = x[["result"]][[id]][["sortpubdate"]],
        fulljournalname = x[["result"]][[id]][["fulljournalname"]],
        volume = x[["result"]][[id]][["volume"]],
        elocationId = x[["result"]][[id]][["elocationid"]],
        title = x[["result"]][[id]][["title"]],
        authors = x[["result"]][[id]][["authors"]] %>%
            rlist::list.stack() %>%
            pull(name) %>%
            paste0(., collapse = ", ")
    )
}

# build_df
# Compile results from `get_metadata` into a tidy object
pubmed$build_df <- function(x) {
    x %>%
        # clean publication data and prepare html attributes for
        # doi link
        mutate(
            sortpubdate = lubridate::ymd_hm(sortpubdate) %>%
                as.Date(.),
            doi_url = stringr::str_replace_all(
                string = elocationId,
                pattern = "doi: ",
                replacement = "https://doi.org/"
            ),
            doi_label = stringr::str_replace_all(
                string = elocationId,
                pattern = "doi: ",
                replacement = ""
            )
        ) %>%
        select(-elocationId) %>%
        arrange(desc(sortpubdate)) %>%
        mutate(
            sortpubdate = lubridate::year(sortpubdate),
            html_order = rev(seq_len(length(uid)))
        )
}