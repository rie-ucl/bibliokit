#' Generate a ranking of the top keywords used in the provided Scopus search results.
#'
#' @param res A list containing Scopus search results, including entries with `authkeywords` and `dc:description`.
#' @param n An integer specifying the number of top keywords to return. Defaults to 20.
#' @param abst A logical value indicating whether to include keywords from the abstracts. Default is `FALSE`.
#' @return A tibble with columns
#'            `rank` (integer, rank),
#'            `keyword` (character, keyword), and
#'            `n` (integer, occurrence count).
#' @examples
#' res <- list(
#'   entries = list(
#'     list( authkeywords = "machine learning | AI | deep learning",
#'           `dc:description` = "This is an abstract about AI." ),
#'     list( authkeywords = "machine learning | data mining",
#'           `dc:description` = "Abstract about data mining and machine learning." )
#'   )
#' )
#'
#' rank_keyword( res, abst = TRUE )
#'
#' @import utils
#'
#' @export

rank_keyword <- function( res, n = 20, abst = FALSE ) {

  keywords <- unlist( lapply( res$entries, function( entry ) {
    if( !is.null( entry$authkeywords ) ) {
      tolower( trimws( unlist( strsplit( entry$authkeywords, "\\|" ) ) ) )
    }
  } ) )

  if( abst ) {
    abstracts <- unlist( lapply( res$entries, function(e) e$`dc:description` ) )
    abst_keywords <- litsearchr::extract_terms (
      text = abstracts,
      method = "fakerake",
      min_freq = 3,
      min_n = 2,
      stopwords = litsearchr::get_stopwords()
    )
    keywords <- c( keywords, abst_keywords )
  }

  top_keywords <- tibble::tibble( keyword = keywords ) |>
    dplyr::count( keyword, sort = TRUE ) |>
    utils::head( n ) |>
    dplyr::mutate( rank = dplyr::row_number(), .before = 1 )

  return( top_keywords )

}
