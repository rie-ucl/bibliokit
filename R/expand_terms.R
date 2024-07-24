#' Expand Search Terms
#'
#' This function takes one or more initial search terms and returns
#' a query (expanded set of terms) by including related or similar terms.
#' The expansion helps to capture more relevant results by broadening the search criteria.
#'
#' @param naive_terms A character vector of one or more initial search queries.
#' @return A character vector containing the original queries along with expanded queries.
#' @examples
#' # Single query
#' expand_terms("data analysis")
#'
#' # Multiple queries
#' expand_terms(c("data analysis", "machine learning"))
#'
#' @export

expand_terms <- function( naive_terms ) {

  QUERY = paste0( "TITLE-ABS-KEY (", paste0('"', naive_terms, '"', collapse = ' AND '), ")" )
  # CTIME = format( Sys.time(), "%Y%m%d_%H%M" )

  res <- rscopus::scopus_search(
          query = QUERY,
          view = "COMPLETE", # to include all authors, COMPLETE view is needed
          count = 25,        # to use COMPLETE view, count should be below 25
          max_count = 25
         )

  entries = res$entries

  my_stopwords_path <- system.file( "extdata", "my_stopwords", package = "bibliokit" )
  all_stopwords <- c( litsearchr::get_stopwords( "English" ), readr::read_lines( my_stopwords_path ) )

  # keyword extraction
  naive_keywords <- unlist( lapply( entries, function(x) x$authkeywords ) )
  naive_keywords <- gsub( "\\|", "and", naive_keywords )
  keywords <- litsearchr::extract_terms(
    keywords = naive_keywords,
    method = "tagged",
    min_freq = 1,
    min_n = 1,
    stopwords = all_stopwords
  )

  # title extraction
  naive_titles <- unlist( lapply( entries, function(x) x$`dc:title` ) )
  title_terms <- litsearchr::extract_terms (
    text = naive_titles,
    method = "fakerake",
    min_freq = 1,
    min_n = 1,
    stopwords = all_stopwords
  )

  terms <- unique( c( keywords, title_terms ) )

  # network analysis
  naive_abstracts <- unlist( lapply( entries, function(x) x$`dc:description` ) )
  docs <- paste( naive_titles, naive_abstracts )
  dfm <- litsearchr::create_dfm( elements = docs, features = terms )
  g <- litsearchr::create_network( dfm, min_studies = 5 )

  # ggraph( g, layout = "stress" ) +
  #   coord_fixed() +
  #   expand_limits( x = c( -3, 3 ) ) +
  #   geom_edge_link( aes( alpha = weight ) ) +
  #   geom_node_point( shape = "circle filled", fill = "white" ) +
  #   geom_node_text( aes( label = name ), hjust = "outward", check_overlap = TRUE ) +
  #   guides( edge_alpha = FALSE )

  # strengths <- igraph::strength( g )

  # term_strengths <- data.frame(
  #   term = names( strengths ),
  #   strength = strengths,
  #   row.names = NULL
  # ) |>
  #   dplyr::mutate( rank = rank( strength, ties.method = "min" ) ) |>
  #   dplyr::arrange( strength )

  cutoff_cum <- litsearchr::find_cutoff( g, method = "cumulative", percent = 0.8 )

  selected_terms <- litsearchr::get_keywords( litsearchr::reduce_graph( g, cutoff_cum ) )

  expanded_query <- paste0( "TITLE-ABS-KEY (", paste0('"', selected_terms, '"', collapse = ' AND '), ")" )

  return( expanded_query )
}
