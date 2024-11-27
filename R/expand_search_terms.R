#' Expand Search Terms
#'
#' The `expand_search_terms()` function takes one or more initial search terms and
#' returns a query (expanded set of terms) by including related or similar terms.
#' The expansion helps to capture more relevant results by broadening the search.
#'
#' @param naive_terms A character vector of one or more initial search queries.
#' @return A character vector containing the original queries along with expanded search terms.
#' @examples
#' expand_search_terms( c( "data analysis", "machine learning" ) )
#'
#' @import utils
#' @import igraph
#' @import dplyr
#'
#' @export

expand_search_terms <- function( naive_terms ) {

  QUERY <-
    paste0( "TITLE-ABS-KEY (",
            ifelse( length(naive_terms) > 1 ,
                    paste0('"', naive_terms, '"', collapse = ' AND '),
                    naive_terms
                    ),
            ")" )

  res <- rscopus::scopus_search(
          query = QUERY,
          view = "COMPLETE", # to include all authors, COMPLETE view is needed
          count = 25,        # to use COMPLETE view, count should be below 25
          max_count = 200
         )

  entries = res$entries

  my_stopwords_path <- system.file( "extdata", "my_stopwords",
                                    package = "bibliokit" )
  all_stopwords <- c( litsearchr::get_stopwords( "English" ),
                      readr::read_lines( my_stopwords_path ) )

  # keyword extraction
  naive_keywords <- unlist( lapply( entries, function(x) x$authkeywords ) )
  naive_keywords <- gsub( "\\|", "and", naive_keywords )
  keywords <- litsearchr::extract_terms(
    keywords = naive_keywords,
    method = "tagged",
    min_n = 1,
    min_freq = 1,
    stopwords = all_stopwords
  )

  # title extraction
  naive_titles <- unlist( lapply( entries, function(x) x$`dc:title` ) )
  title_terms <- litsearchr::extract_terms (
    text = naive_titles,
    method = "fakerake",
    min_freq = 3,
    min_n = 2,
    stopwords = all_stopwords
  )

  naive_abstracts <- unlist( lapply( entries, function(x) x$`dc:description` ) )
  abst_terms <- litsearchr::extract_terms(
    text = naive_abstracts,
    method = "fakerake",
    min_freq = 3,
    min_n = 2,
    stopwords = all_stopwords
  )

  # integration
  terms <- unique( c( keywords, title_terms, abst_terms ) )

  # network analysis
  # naive_abstracts <- unlist( lapply( entries, function(x) x$`dc:description` ) )
  docs <- paste( naive_titles, naive_abstracts )
  dfm <- litsearchr::create_dfm( elements = docs, features = terms )
  g <- litsearchr::create_network( dfm, min_studies = 5 )

  strengths <- igraph::strength(g)

  term_strengths <- data.frame( term = names( strengths ), strength = strengths, row.names=NULL) |>
    dplyr::mutate( rank = rank( strength, ties.method = "min" ) ) |>
    dplyr::arrange( strength )

  term_strengths |>
    ggplot2::ggplot( ggplot2::aes( x = rank, y = strength, label = term ) ) +
    ggplot2::geom_line() +
    ggplot2::geom_point() +
    ggplot2::geom_text( data = dplyr::filter( term_strengths, rank > 5 ),
               hjust = "right", nudge_y = 20, check_overlap = TRUE)

  cutoff_cum <- litsearchr::find_cutoff( g, method = "cumulative", percent = 0.8 )

  selected_terms <- litsearchr::get_keywords( litsearchr::reduce_graph( g, cutoff_cum ) )

  return( selected_terms )
}
