#' Extract search terms from a Scopus search URL.
#'
#' This function extracts search keywords from the provided Scopus search URL
#' within the `res` object. The URL is obtained from `res$get_statements$url`.
#'
#' @param res A list containing Scopus search results, with a URL field in `get_statements`.
#' @return A list of search keywords extracted from the URL.
#' @export
#' @examples
#' res <- list(
#'   get_statements = list(
#'     url = "https://api.elsevier.com/content/search/scopus?query=TITLE-ABS-KEY%20%28%22artificial%20intelligence%22%20AND%20%22national%20security%22%20OR%20%22machine%20learning%22%29"
#'   )
#' )
#' #' get_search_terms( res )
#'
#' @export

get_search_terms <- function( res ) {

  url <- res$get_statements$url

  query <- sub(".*query=", "", url)
  query_decoded <- URLdecode(query)

  terms_raw <- gsub("^.*\\((.*)\\).*$", "\\1", query_decoded)
  terms_raw <- strsplit(terms_raw, " OR | AND ")[[1]]
  terms <- gsub('"', '`', terms_raw)
  terms <- trimws(terms)

  return(terms)
}
