#' Scopus Country Analysis
#'
#' This function analyzes the countries associated with publications
#' from Scopus search results and provides various insights such as
#' country rankings, global share, and trends over years.
#'
#' @param res A list containing Scopus search results with a component
#'   `entries` which is a list of publication details. Each entry should
#'   have the fields `dc:title`, `prism:coverDate`, and `affiliation`
#'   (with `affiliation-country`).
#' @return A ggplot2 object showing the analysis results.
#' @examples
#' # Create a sample `res` list to simulate Scopus API search results
#' res <- list(
#'   entries = list(
#'     list(
#'       `dc:title` = "A Study on Data Analysis",
#'       `prism:coverDate` = "2022-12-31",
#'       affiliation = list(
#'         list(
#'           `affiliation-country` = "United States"
#'         )
#'       )
#'     ),
#'     list(
#'       `dc:title` = "Advances in Machine Learning",
#'       `prism:coverDate` = "2022-11-30",
#'       affiliation = list(
#'         list(
#'           `affiliation-country` = "China"
#'         )
#'       )
#'     ),
#'     list(
#'       `dc:title` = "Research in Quantum Computing",
#'       `prism:coverDate` = "2022-10-15",
#'       affiliation = list(
#'         list(
#'           `affiliation-country` = "Germany"
#'         )
#'       )
#'     ),
#'     list(
#'       `dc:title` = "Innovations in AI",
#'       `prism:coverDate` = "2022-09-01",
#'       affiliation = list(
#'         list(
#'           `affiliation-country` = "United Kingdom"
#'         )
#'       )
#'     ),
#'     list(
#'       `dc:title` = "Exploring New Frontiers in Science",
#'       `prism:coverDate` = "2022-08-01",
#'       affiliation = list(
#'         list(
#'           `affiliation-country` = NULL
#'         )
#'       )
#'     )
#'   )
#' )
#'
#' # Example usage of the function with the sample data
#' scopus_country_analysis(res)
#'
#' @export



scopus_country_analysis <- function( res ) {

  entries <- res$entries

  data <- lapply( entries, function(entry) {
    title <- entry$`dc:title`
    year <- substr( entry$`prism:coverDate`, 1, 4 )
    country <- if ( !is.null(entry$affiliation[[1]]$`affiliation-country`) ) {
      entry$affiliation[[1]]$`affiliation-country`
    } else {
      "Unknown"
    }

    list( title = title, year = year, country = country )
  })

  data.tib <- tibble::tibble(
    title   = sapply( data, `[[`, "title" ),
    year    = sapply( data, `[[`, "year" ),
    country = unlist(lapply( data, `[[`, "country" ))
  )

  top_countries <- data.tib |>
    dplyr::filter( country != "Unknown" )  |>
    dplyr::count( country, sort = TRUE ) |>
    head( 8 ) |>
    dplyr::arrange( n ) |>
    dplyr::pull( country )

  data.tib <- data.tib |>
    dplyr::mutate( year = ifelse( year <= 2015, "-2015", year )) |>
    dplyr::mutate( year = factor( year ) ) |>
    dplyr::mutate( country = ifelse( country %in% c(top_countries, "Unknown"), country, "Other")) |>
    dplyr::mutate( country = factor( country, levels = c( "Unknown", "Other", top_countries )))

  share_data.tib <- data.tib |>
    dplyr::count( country ) |>
    dplyr::mutate( share = n / sum(n) )

  max_n <- max( dplyr::count( data.tib, country )$n )
  len_n <- length( unique(data.tib$country) )

  (
  g_bar <- data.tib |>
    ggplot2::ggplot() +
      ggplot2::geom_bar( position = ggplot2::position_stack( reverse = TRUE),
                         ggplot2::aes( y = country, fill = year ) ) +
      ggplot2::geom_text( stat = "count", ggplot2::aes( y = country, label = ..count.. ), hjust = -.5 ) +
      ggplot2::scale_fill_brewer( palette = "RdBu" ) +

      ggplot2::geom_point( data = share_data.tib,
                           ggplot2::aes( x = max(n) * 1.15, y = country, size = share ),
                           shape = 21, fill = "lightblue", colour = "lightblue",
                           show.legend = FALSE ) +
      ggplot2::geom_text( data = share_data.tib,
                          ggplot2::aes( x = max(n) * 1.25 , y = country, label = sprintf("%.1f%%", share*100) ),
                          colour = "navy", show.legend = FALSE ) +
      ggplot2::annotate( "text", x = max_n*0.5, y = len_n + 1, label = "Total Number of Publications" ) +
      ggplot2::annotate( "text", x = max_n*1.2 , y = len_n + 1, label = "Global Share" ) +
      ggplot2::scale_size_continuous( range = c( 0, 20 )) +

      ggplot2::scale_x_discrete( expand = c(0,0,0.10,0) ) +
      ggplot2::scale_y_discrete( expand = c(0,0,0,1.5) ) +

      ggplot2::theme_minimal() +
      ggplot2::labs( x = "Number and Global Share of Publications",
                     y = "Country",
                     fill = "" ) +
      ggplot2::theme(
        legend.position = "inside",
        legend.position.inside = c(0.65, 0.5),
        legend.box = "vertical"
      )
  )

  data2024.tib <- data.tib |>
    dplyr::filter( year == 2024 & country %in% top_countries ) |>
    dplyr::count( country, year )

  (
  g_line <- data.tib |>
    dplyr::group_by( year, country ) |>
    dplyr::summarise( n = dplyr::n(), .groups = "drop" ) |>
    tidyr::complete( year, country, fill = list( n = 0 ) ) |>
    dplyr::filter( year != "-2015" & country %in% top_countries ) |>
    ggplot2::ggplot( mapping = ggplot2::aes( x = year, y = n,
                                             group = country,
                                             colour = country ) ) +
      ggplot2::geom_line( linewidth = 1.5, show.legend = FALSE ) +
      ggrepel::geom_text_repel(
        ggplot2::aes( label = n ), vjust = -1, show.legend = FALSE ) +
      ggrepel::geom_text_repel(
        data = data2024.tib, ggplot2::aes( label = country, y = n ),
        hjust = 0, nudge_x = 0.2, direction = "y", show.legend = FALSE ) +
      ggplot2::scale_x_discrete( expand = c(0,0.5,0,1.5) ) +
      ggplot2::labs( x = "Year", y = "Number of Publications" )
  )

  return( g_bar )
}
