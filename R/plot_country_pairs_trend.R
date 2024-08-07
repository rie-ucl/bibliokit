#' Plot the trend of top country pairs by publication year, optionally filtering for a specific country
#'
#' This function analyzes and visualizes the trend of the most common country pairs in publications over time.
#' It can also filter the pairs to include only those involving a specific country.
#'
#' @param res List structure containing publication data
#' @param n Number of top country pairs to plot (default is 5)
#' @param target_country Optional; specific country to filter the pairs by (default is NULL)
#' @return A plot object showing the trend of top country pairs by publication year
#' @export
#' @import dplyr
#' @import ggplot2
#' @import purrr
#' @import tidyr

plot_country_pairs_trend <- function( res, n = 5, target_country = NULL ) {
  country_pairs <- purrr::map_df( res$entries, function( entry ) {
    countries <- entry$affiliation |>
      purrr::map( ~ .x$`affiliation-country` ) |>
      unlist() |>
      na.omit() |>
      unique()
    if ( length( countries ) < 2 ) {
      return( data.frame( year = character(), pair = character() ) )
    }
    pairs <- combn( countries, 2, simplify = FALSE )
    data.frame(
      year = substr( entry$`prism:coverDate`, 1, 4 ),
      pair = purrr::map_chr( pairs, ~ paste( sort( .x ), collapse = "-" ) )
    )
  })

  if ( !is.null( target_country ) ) {
    country_pairs <- country_pairs |>
      dplyr::filter( grepl( target_country, pair ) )
  }

  top_pairs <- country_pairs |>
    dplyr::count( pair, sort = TRUE ) |>
    dplyr::slice_head( n = n ) |>
    dplyr::pull( pair )

  filtered_data <- country_pairs |>
    dplyr::filter( pair %in% top_pairs ) |>
    dplyr::count( year, pair ) |>
    tidyr::complete( year, pair, fill = list( n = 0 ) )

  plot <- ggplot2::ggplot( filtered_data, ggplot2::aes( x = year, y = n, color = pair, group = pair ) ) +
    ggplot2::geom_line( linewidth = 1 ) +
    ggplot2::geom_point( size = 3, shape = 21, fill = "white" ) +
    ggplot2::geom_text( ggplot2::aes(label = n), vjust = -0.6, size = 3, show.legend = FALSE ) +
    ggplot2::labs( title = "Top Country Pairs by Publication Year", x = "Year", y = "Number of Publications" ) +
    ggplot2::theme_minimal()

  return( plot )
}
