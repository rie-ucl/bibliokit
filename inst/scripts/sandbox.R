

QUERY = 'TITLE-ABS-KEY ( "artificial intelligence" AND "national security" )'
QUERY = 'TITLE-ABS-KEY ( "quantum computing" ) AND PUBYEAR = 2024'
TERMS = "quantum_computing_2024"

res <- rscopus::scopus_search(
  query = QUERY,
  view = "COMPLETE", # to include all authors, COMPLETE view is needed
  count = 25,        # to use COMPLETE view, count should be below 25
  max_count = 5000   # cannot exceed 5000
)

CTIME = format( Sys.time(), "%Y%m%d_%H%M" )
FILEPATH = paste0( "../../research-dissertation/upgrade/literature_review/bibliokit/rscopus-", CTIME , "-", TERMS, ".rda")
save( res, file = FILEPATH )

entries = res$entries



library(httr)

# Set up your API key and endpoint
api_key <- get_api_key()
url <- "https://api.elsevier.com/content/search/scopus?query=TITLE-ABS-KEY(quantum)"

# Make the API request
response <- GET(url, add_headers(Authorization = paste("Bearer", api_key)))

# Extract and print rate limit information
if (status_code(response) == 200) {
  headers <- headers(response)
  rate_limit_remaining <- headers["x-ratelimit-remaining"]
  print(paste("Rate limit remaining:", rate_limit_remaining))
} else {
  print(paste("Error:", status_code(response)))
}
