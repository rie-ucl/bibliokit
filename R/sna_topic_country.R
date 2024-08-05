#' Social Network Analysis - Topic-Country Relationship
#'
#' This function performs a network analysis based on topics (keywords) and countries
#' from the given publication data. It visualizes the relationship between different
#' topics and the countries associated with those topics.
#'
#' @param res A list containing Scopus search results with an `entries` element,
#'   where each entry contains `authkeywords` (keywords separated by '|'),
#'   `dc:description` (abstract), and `affiliation` (containing `affiliation-country`).
#'
#' @return A `ggraph` object that visualizes the network of topics and countries.
#' The plot includes nodes representing topics and countries, with edges showing
#' the connections between them. Nodes are color-coded by their type (topics or countries),
#' and edge thickness is proportional to the number of shared keywords between topics and countries.
#' The color of the edges is determined by the frequency of connections, with a gradient
#' from light blue (low frequency) to dark blue (high frequency).
#'
#' @examples
#' res <- list(
#'   entries = list(
#'     list(
#'       authkeywords = "AI|Machine Learning|Data Science",
#'       dc.description = "This paper discusses advancements in AI and machine learning.",
#'       affiliation = list(
#'         list(`affiliation-country` = "United States"),
#'         list(`affiliation-country` = "China")
#'       )
#'     ),
#'     list(
#'       authkeywords = "Quantum Computing|AI",
#'       dc.description = "Explores quantum computing and its applications in AI.",
#'       affiliation = list(
#'         list(`affiliation-country` = "Germany")
#'       )
#'     )
#'   )
#' )
#'
#' sna_topic_country( res )
#'
#' @export

sna_topic_country <- function( res ) {

  entries <- res$entries

  topics_countries <- data.frame(
    topic = character(),
    country = character(),
    stringsAsFactors = FALSE
  )

  for ( entry in entries ) {
    if ( !is.null( entry$authkeywords ) && !is.null( entry$affiliation ) ) {
      keywords <- unlist( strsplit( entry$authkeywords, "\\|") )
      keywords <- tolower( trimws( keywords ) )

      countries <- unique( sapply( entry$affiliation, function(x) x$`affiliation-country` ) )
      countries <- countries[!is.na(countries) & countries != ""]

      if ( length( countries ) > 0 && length( keywords ) > 0) {
        for ( keyword in keywords ) {
          if ( keyword != "" ) {
            for ( country in countries) {
              if ( country != "" ) {
                topics_countries <-
                  rbind( topics_countries,
                         data.frame( topic = keyword,
                                     country = country,
                                     stringsAsFactors = FALSE) )
              }
            }
          }
        }
      }
    }
  }

  topic_ranking <- topics_countries |>
    dplyr::count( topic ) |>
    dplyr::arrange( dplyr::desc(n) )

  country_ranking <- topics_countries |>
    dplyr::count( country ) |>
    dplyr::arrange( dplyr::desc(n) )

  top_countries <- country_ranking |> head(6)  |> dplyr::pull(country)
  top_topics    <- topic_ranking   |> head(10) |> dplyr::pull(topic)

  top_data <- topics_countries |>
    dplyr::filter( topic %in% top_topics, country %in% top_countries )

  edges <- top_data |>
    dplyr::count( topic, country ) |>
    as.data.frame()

  nodes <- unique( c( as.character( edges$topic ), as.character( edges$country ) ) )

  node_type <- ifelse( nodes %in% unique( edges$country ), TRUE, FALSE )

  g <- igraph::graph_from_data_frame(
    edges, vertices = data.frame( name = nodes, type = node_type ) )

  igraph::V(g)$size <- igraph::degree(g)
  max_n <- max( igraph::E(g)$n )

  layout <- igraph::layout_as_bipartite( g, types = igraph::V(g)$type )
  layout <- layout[ , c(2, 1) ]
  layout[igraph::V(g)$type == TRUE,  1] <- layout[igraph::V(g)$type == TRUE,  1] + 0.2
  layout[igraph::V(g)$type == FALSE, 1] <- layout[igraph::V(g)$type == FALSE, 1] - 0.2

  (
  g_bi <- ggraph::ggraph( g, layout = layout ) +
    ggraph::geom_edge_link(
      ggplot2::aes( width = n/max_n * 3,
                    colour = paste0("gray",80-as.integer(n*80/max_n)) ),
      show.legend = FALSE ) +
    ggraph::geom_node_point( ggplot2::aes( size = size,
                                           colour = type, fill = type ),
                             position = ggplot2::position_dodge( width = 0.4 ),
                             shape = 21, show.legend = FALSE ) +
    ggraph::geom_node_text( ggplot2::aes( label = name, hjust = ifelse( type, 1, 0 ),
                                          x = x + ifelse( type, -0.01, 0.01 ) ) ) +
    ggplot2::scale_fill_brewer(
      palette = "Set1", direction = -1, aesthetics = c( "colour", "fill" ) ) +
    ggplot2::theme_void()
  )

  return( g_bi )
}
