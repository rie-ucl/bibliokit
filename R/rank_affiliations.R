#' Generate a ranking of the top affiliation used in the provided Scopus search results.
#'
#' The `rank_affiliations()` function generates a ranking of the top affiliations
#' from the provided Scopus search results,
#' based on the number of publications and total citations.
#' By choosing the `type = "city"` or `type = "institution"` option,
#' the function can provide the ranking of cities or institutions instead of countries.
#' The output is a tibble with the following columns:
#' `rank` rank of the affiliation,
#' `country/city/institution` type of the affiliation, and
#' `n` number of publications.
#'
#' @param res A list containing Scopus search results, including entries with `affiliation`.
#' @param n An integer specifying the number of top keywords to return. Defaults to 20.
#' @param type A character indicating what to rank. The value should be `country`, `city`, or `institution`. Default is `country`.
#'
#' @return A tibble with columns
#'            `rank` (integer, rank),
#'            `institution/country/city` (character), and
#'            `n` (integer, occurrence count).
#'
#' @examples
#' # Load a sample Scopus search result object (res)
#' # Note: This is a placeholder example. In practice, you would load or obtain a real 'res' object.
#' res <- list(
#'   entries = list(
#'     list(
#'       affiliation = list(
#'         list(
#'           `affiliation-country` = c("USA", "Canada", "Germany"),
#'           `affiliation-city` = c("New York", "Toronto", "Berlin"),
#'           `affilname` = c("Johns Hopkins University")
#'         )
#'       )
#'     ),
#'     list(
#'       affiliation = list(
#'         list(
#'           `affiliation-country` = c("USA", "France", "Germany"),
#'           `affiliation-city` = c("San Francisco", "Paris", "Berlin"),
#'           `affilname` = c("University of California")
#'         )
#'       )
#'     )
#'   )
#' )
#'
#' # Generate a ranking of the top 20 countries
#' rank_affiliations( res )
#'
#' # Generate a ranking of the top 20 cities
#' rank_affiliations( res, n = 20, type = "city")
#'
#' @import tibble
#' @import dplyr
#' @import utils
#'
#' @export

rank_affiliations <- function( res, n = 20, type = "country" ) {

  affils <- unlist( lapply( res$entries, function(e) {
      unlist( lapply( e$affiliation, function(a) {
        if( type=="institution" ) paste( a$affilname, a$`affiliation-country`, sep = ", " )
        else if( type=="city" )   paste( a$`affiliation-city`, a$`affiliation-country`, sep = ", " )
        else a$`affiliation-country`
      } ) )
  } ) )

  top_affils <- tibble::tibble( affil = affils ) |>
    dplyr::count( affil, sort = TRUE ) |>
    utils::head( n ) |>
    dplyr::mutate( rank = dplyr::row_number(), .before = 1 )

  if( type=="institution" ) {
    top_affils <- dplyr::rename( top_affils, institution = affil )
  } else if( type=="city" ) {
    top_affils <- dplyr::rename( top_affils, city = affil )
  } else {
    top_affils <- dplyr::rename( top_affils, country = affil )
  }

  return( top_affils )

}
