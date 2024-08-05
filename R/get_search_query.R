#' Extract the search query from a given URL.
#'
#' This function extracts the search query string from a URL containing
#' Scopus API search parameters.
#'
#' @param res A list containing Scopus search results, with a URL field in `get_statements`.
#' @return A character string containing the search query.
#' @examples
#' res <- list(
#'   get_statements = list(
#'     url = "https://api.elsevier.com/content/search/scopus?query=TITLE-ABS-KEY%20%28%22artificial%20intelligence%22%20AND%20%22national%20security%22%20OR%20%22machine%20learning%22%29"
#'   )
#' )
#' #' get_search_query( res )
#'
#' @import utils
#'
#' @export

get_search_query <- function( res ) {

  url <- res$get_statements$url

  parsed_url <- httr::parse_url(url)

  query_param <- parsed_url$query$query

  query_decoded <- URLdecode(query_param)

  query <- gsub("^\"|\"$", "", query_decoded)

  return(query)
}
