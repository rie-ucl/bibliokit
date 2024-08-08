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
  url <- res$get_statements$url

  query <- sub(".*query=", "", url)
  query_decoded <- URLdecode( query )

  terms <- list()

  query_parts <- unlist( strsplit( query_decoded, "\\s+(AND|OR)\\s+") )

  query_types <- unique( gsub("\\((.*)\\)", "", query_parts) )

  for (query_type in query_types) {
    type_regex <- paste0(query_type, "\\(([^)]+)\\)")
    type_matches <- regexpr(type_regex, query_decoded, perl=TRUE)

    if (type_matches[1] != -1) {
      values_part <- regmatches(query_decoded, type_matches)
      values_str <- sub(type_regex, "\\1", values_part)
      values <- trimws(gsub('"', '', values_str))

      values_split <- unlist(strsplit(values, "\\s+(AND|OR)\\s+"))
      terms[[query_type]] <- trimws( values_split )
    }
  }

  return(terms)
}
