#' Plot Country Overview
#'
#' The `plot_country_overview()` function analyses and visualise
#' the countries associated with publications
#' from Scopus search results.
#'
#' @param res Scopus search results, including `entries`, which is a list of publication details.
#'   Each entry should have the fields `dc:title`, `prism:coverDate`, and `affiliation`
#'   (with `affiliation-country`).
#'
#' @return A ggplot2 object showing the analysis results.
#'
#' @examples
#' res = list(
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
#' plot_country_overview( res )
#'
#' @import utils
#' @import dplyr
#'
#' @export

plot_country_overview <- function( res ) {

  entries <- res$entries

  data <- lapply( entries, function( entry ) {
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
    country = unlist( lapply( data, `[[`, "country" ) )
  )

  top_countries <- data.tib |>
    dplyr::filter( country != "Unknown" )  |>
    dplyr::count( country, sort = TRUE ) |>
    utils::head( 8 ) |>
    dplyr::arrange( n ) |>
    dplyr::pull( country )

  latest_year <- ifelse(
    !is.null( res$meta_data ) && !is.null( res$meta_data$end_year ),
    res$meta_data$end_year,
    max( as.numeric( format( as.Date(
      sapply( res$entries, function(x) x$`prism:coverDate` ) ), "%Y" ) ), na.rm = TRUE )
  )

  data.tib <- data.tib |>
    dplyr::mutate( year = ifelse( year <= latest_year-10, paste0( "-", latest_year-10 ), year )) |>
    dplyr::mutate( year = factor( year ) ) |>
    dplyr::mutate( country = ifelse( country %in% c(top_countries, "Unknown"), country, "Other")) |>
    dplyr::mutate( country = factor( country, levels = c( "Unknown", "Other", top_countries )))

  share_data.tib <- data.tib |>
    dplyr::count( country ) |>
    dplyr::mutate( share = n / sum(n) )

  max_n <- max( dplyr::count( data.tib, country )$n )
  len_n <- length( unique(data.tib$country) )

  g_bar <- data.tib |>
    ggplot2::ggplot() +
    ggplot2::geom_bar( position = ggplot2::position_stack( reverse = TRUE),
                       ggplot2::aes( y = country, fill = year ) ) +
    ggplot2::geom_text( stat = "count", ggplot2::aes( y = country, label = ggplot2::after_stat(count) ),
                        size = 3, hjust = 0, nudge_x = max_n * 0.01 ) +
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
    ggplot2::scale_size_continuous( range = c( 0, 8 )) +
    ggplot2::scale_x_discrete( expand = c(0,0,0.10,0) ) +
    ggplot2::scale_y_discrete( expand = c(0,0,0,1.5) ) +
    ggplot2::theme_minimal() +
    ggplot2::labs( x = "Number and Global Share of Publications",
                   y = "Country",
                   fill = "" ) +
    ggplot2::theme(
      legend.position = "inside",
      legend.position.inside = c(0.65, 0.5),
      legend.box = "vertical",
      legend.key.size = ggplot2::unit( 0.3, "cm" ),
      legend.text = ggplot2::element_text( size = 6.5 )
    )

  return( g_bar )
}
