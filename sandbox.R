

QUERY = 'TITLE-ABS-KEY ( "artificial intelligence" AND "national security" )'

res <- rscopus::scopus_search(
  query = QUERY,
  view = "COMPLETE", # to include all authors, COMPLETE view is needed
  count = 25,        # to use COMPLETE view, count should be below 25
  max_count = 500
)

CTIME = format( Sys.time(), "%Y%m%d_%H%M" )
FILEPATH = paste0( "../../research-dissertation/upgrade/literature_review/bibliokit/rscopus_", CTIME , ".rda")
save( res, file = FILEPATH )

entries = res$entries
