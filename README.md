# Update Publications Workflow

This project demonstrations how to create a GitHub Action that updates a publication list using the Pubmed API. This approach uses a few custom methods (see `R/pubmed.R`) for running pubmed queries. Data is saved in the `data` folder. The github workflow is scheduled to run every friday `0 9 * * 5`. All changes are returned as a pull request via the GitHub Actions bot.

## Getting Started

This is really a proof of concept workflow. I wanted to see if this would work and if it would be practical for another project. There are several packages for sending queries to the Pubmed API, but I needed a specific data elements which those packages did not return.

### 1. Initialize queries and publications

This workflow works by relying on a set of queries and an existing publications dataset. To get started, you will have to manually initialize these datasets. (You will only need to do this once.)

#### 1a. Create queries object

To get publication data from Pubmed, you must first get publication IDs. This workflow uses an object of one or more queries to find relevant publications. Define the queries as a typical dataframe (use `c()` to create more than one entry).

```r
queries <- data.frame(
    id = "q_01",
    type = "author_corporate",
    query = "American Diabetes Association[Corporate Author]"
)
```

Use the [Pubmed's advanced query builder](https://pubmed.ncbi.nlm.nih.gov/advanced/) to test your queries. Add as many as you like.

#### 1b. Fetch IDs

Once you have tested your queries, run the function `pubmed$get_ids`.

```r
pub_ids <- unlist(
    lapply(
        queries$query, function(x) {
            pubmed$get_ids(query = x)
        }
    )
)
```

#### 1c. Fetch publications

Using the object containing publication IDs, you can fetch publication data by running the function: `pubmed$get_metadata`.

```r
results <- pubmed$get_metadata(
    ids = pub_ids
    delay = 0.75  # delay: pause between requests in milliseconds
)
```

The value between delay is recommended. Otherwise, you will get timeout errors or may be locked out for a period of time. I like to randomize the delay using the following: `sample(runif(100, 0.75, 2), length(pub_ids))`

#### 1d. Save objects

Next, save the queries object and publications data. These will be your baseline and used in GitHub workflow.

```r
write.csv(queries, "data/api_queries.csv", row.names = FALSE)
write.csv(results, "data/publications.csv", row.names = FALSE)
```

Create a new GitHub repo and commit changes.

### 2. Update links in `update.R` script

The workflow works by reading the queries object and removing publication IDs that are already known. In the file `update.R`, update the `read.csv` paths with the url to your datasets on `raw.githubusercontent.com`.

Commit changes and push to your GitHub repository.
