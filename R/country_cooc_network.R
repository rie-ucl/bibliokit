#' Create a Network of Country Co-occurrences
#'
#' This function analyzes co-occurrence data between countries based on shared keywords
#' and creates a network graph visualizing the relationships between countries.
#' The network is constructed based on the frequency of shared keywords between countries.
#' The resulting graph can help in understanding how countries are connected through common research topics.
#'
#' @param res A list containing Scopus search results, which includes:
#'   - `entries`: A list of publication entries where each entry contains:
#'     - `authkeywords`: Keywords related to the publication, separated by `|`.
#'     - `affiliation`: A list of affiliation details, including:
#'       - `affiliation-country`: The country associated with the publication's affiliation.
#'
#' @return A `ggraph` object showing the network of countries based on their co-occurrence in research topics.
#'   The network visualizes countries as nodes and the strength of their connections (based on shared keywords)
#'   as edges between these nodes. Nodes are sized according to their importance in the network, and edges
#'   are colored based on their weight.
#'
#' @examples
#' # Example of `res` with dummy data
#' res <- list(
#'   entries = list(
#'     list(
#'       authkeywords = "Artificial Intelligence|Machine Learning",
#'       affiliation = list(
#'         list( `affiliation-country` = "USA" )
#'       )
#'     ),
#'     list(
#'       authkeywords = "Artificial Intelligence|Data Science",
#'       affiliation = list(
#'         list( `affiliation-country` = "UK" )
#'       )
#'     ),
#'     list(
#'       authkeywords = "Machine Learning|Data Science",
#'       affiliation = list(
#'         list( `affiliation-country` = "Canada")
#'       )
#'     ),
#'     list(
#'       authkeywords = "Artificial Intelligence|Machine Learning|Data Science",
#'       affiliation = list(
#'         list( `affiliation-country` = "Germany")
#'       )
#'     )
#'   )
#' )
#'
#' # Create the network graph
#' network_graph <- country_cooc_network( res )
#' print( network_graph )
#'
#' @export

country_cooc_network <- function( res ) {

  topics_countries <- data.frame(
    topic = character(),
    country = character(),
    stringsAsFactors = FALSE
  )

  for ( entry in res$entries ) {
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

  country_pairs <- topics_countries |>
    dplyr::group_by(topic)  |>
    dplyr::summarise(countries = list(country), .groups = 'drop')  |>
    dplyr::rowwise() |>
    dplyr::filter( length( countries ) > 1 ) |>
    dplyr::mutate(pairs = list(t(combn(countries, 2)))) |>
    tidyr::unnest(pairs) |>
    dplyr::count(V1 = pairs[,1], V2 = pairs[,2], name = "co" )

  country_matrix <- country_pairs |>
    tidyr::pivot_wider( names_from = V2, values_from = co, values_fill = 0 )

  g <- igraph::graph_from_data_frame( country_pairs, directed = FALSE )

  g_kk <- ggraph::ggraph( g, layout = "kk" ) +
    ggraph::geom_edge_link(
      ggplot2::aes( edge_width = co, edge_alpha = co ), show.legend = FALSE ) +
    ggraph::geom_node_point(
      ggplot2::aes( size = igraph::degree( g, mode = "all" ) + 1, colour = name, fill = name ),
      shape = 21, show.legend = FALSE ) +
    ggraph::geom_node_text( ggplot2::aes( label = name ), repel = TRUE, size = 3 ) +
    ggraph::scale_edge_width( range = c( 0.1, 4 ) ) +
    ggraph::scale_edge_alpha( range = c( 0.1, 0.5 ) ) +
    ggraph::scale_color_viridis( discrete = TRUE, option = "inferno" ) +
    ggraph::scale_fill_viridis( discrete = TRUE, option = "inferno" ) +
    ggplot2::theme_minimal()

  return( g_kk )
}
