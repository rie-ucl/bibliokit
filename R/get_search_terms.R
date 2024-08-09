#' Extract search terms from a Scopus search URL.
#'
#' This function extracts search keywords and other query parameters from the provided Scopus search URL
#' within the `res` object. The URL is obtained from `res$get_statements$url`.
#'
#' @param res A list containing Scopus search results, with a URL field in `get_statements`.
#' @return A list containing the search keywords and other query parameters.
#' @export
#' @examples
#' res <- list(
#'   get_statements = list(
#'     url = "https://api.elsevier.com/content/search/scopus?query=TITLE-ABS-KEY%20%28%20%22oryza%20sativa%22%20%29%20%20AND%20PUBYEAR%20%3D%202014&count=25&start=0&view=COMPLETE"
#'   )
#' )
#' get_search_terms(res)
#'
#' @import utils
#'
#' @export

get_search_terms <- function( res ) {

  query <- URLdecode( sub(".*query=", "", res$get_statements$url) )

  query_parts <- strsplit( query, "\\s*(AND|OR|&)(?=(?:[^()]*\\([^()]*\\))*[^()]*$)", perl=TRUE )
  query_parts <- trimws( query_parts[[1]] )

  terms <- tibble::tibble( type = character(), value = character() )

  for ( query_part in query_parts ) {
    if( grepl( "=", query_part ) ) {
      split_part <- unlist( strsplit( query_part, "=", fixed = TRUE ) )
      type <- trimws( split_part[1] )
      value <- trimws( split_part[2] )
    } else if ( grepl( "\\(", query_part ) ) {
      type <- trimws( sub( "\\(.*$", "", query_part ) )
      value <- trimws( gsub( "^.*\\(|\\)$", "", query_part ) )
      value <- trimws( gsub( '\\"', '`', value ) )
      if ( grepl( "AND|OR", value ) ) {
        value <- strsplit( value, "\\s*(AND|OR)\\s*", perl=TRUE )[[1]]
        value <- trimws( gsub( '\\"', '`', value ) )
        value <- paste( value, collapse = ", " )
      }
    } else {
      type <- trimws( query_part )
      value <- TRUE
    }
    terms <- tibble::add_row( terms, type = type, value = value )
  }

  return( terms )
}
