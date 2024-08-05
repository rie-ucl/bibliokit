#' Plot Sponsor Overview
#'
#' This function analyzes the sponsors associated with publications
#' from Scopus search results and provides various insights such as
#' sponsor rankings, global share, and trends over years.
#'
#' @param res Scopus search results, including `entries`, which is a list of publication details.
#'   Each entry should have the fields `dc:title`, `prism:coverDate`, and `fund-sponsor` (with `fund-acr` for abbreviation).
#' @return A ggplot2 object showing the analysis results.
#' @examples
#' # Create a sample `res` list to simulate Scopus API search results
#' res = list(
#'   entries = list(
#'     list(
#'       `dc:title` = "A Study on Data Analysis",
#'       `prism:coverDate` = "2022-12-31",
#'       `fund-sponsor` = "National Science Foundation",
#'       `fund-acr` = "NSF"
#'     ),
#'     list(
#'       `dc:title` = "Advances in Machine Learning",
#'       `prism:coverDate` = "2022-11-30",
#'       `fund-sponsor` = "China Scholarship Council",
#'       `fund-acr` = "CSC"
#'     ),
#'     list(
#'       `dc:title` = "Research in Quantum Computing",
#'       `prism:coverDate` = "2022-10-15",
#'       `fund-sponsor` = "German Research Foundation",
#'       `fund-acr` = "DFG"
#'     ),
#'     list(
#'       `dc:title` = "Innovations in AI",
#'       `prism:coverDate` = "2022-09-01",
#'       `fund-sponsor` = "Engineering and Physical Sciences Research Council",
#'       `fund-acr` = "EPSRC"
#'     ),
#'     list(
#'       `dc:title` = "Exploring New Frontiers in Science",
#'       `prism:coverDate` = "2022-08-01",
#'       `fund-sponsor` = NULL,
#'       `fund-acr` = NULL
#'     )
#'   )
#' )
#'
#' # Example usage of the function with the sample data
#' plot_sponsor_overview( res )
#'
#' @import dplyr
#'
#' @export

plot_sponsor_overview <- function( res ) {

  entries <- res$entries

  data <- lapply( entries, function( entry ) {
    title <- entry$`dc:title`
    year <- substr( entry$`prism:coverDate`, 1, 4 )
    sponsor <- if ( !is.null(entry$`fund-sponsor`) ) {
      entry$`fund-sponsor`
    } else {
      "Unknown"
    }

    list( title = title, year = year, sponsor = sponsor )
  })

  data.tib <- tibble::tibble(
    title    = sapply( data, `[[`, "title" ),
    year     = sapply( data, `[[`, "year" ),
    sponsor  = unlist( lapply( data, `[[`, "sponsor" ) )
  )

  top_sponsors <- data.tib |>
    dplyr::filter( sponsor != "Unknown" )  |>
    dplyr::count( sponsor, sort = TRUE ) |>
    utils::head( 8 ) |>
    dplyr::arrange( n ) |>
    dplyr::pull( sponsor )

  latest_year <- ifelse(
    !is.null( res$meta_data ) && !is.null( res$meta_data$end_year ),
    res$meta_data$end_year,
    max( as.numeric( format( as.Date(
      sapply( res$entries, function(x) x$`prism:coverDate` ) ), "%Y" ) ), na.rm = TRUE )
  )

  data.tib <- data.tib |>
    dplyr::mutate( year = ifelse( year <= latest_year-10, paste0( "-", latest_year-10 ), year )) |>
    dplyr::mutate( year = factor( year ) ) |>
    dplyr::mutate( sponsor = ifelse( sponsor %in% c(top_sponsors, "Unknown"), sponsor, "Other")) |>
    dplyr::mutate( sponsor = factor( sponsor, levels = c( "Unknown", "Other", top_sponsors )))

  share_data.tib <- data.tib |>
    dplyr::count( sponsor ) |>
    dplyr::mutate( share = n / sum(n) ) |>
    dplyr::filter( sponsor != "Unknown" )

  data.tib <- data.tib |> dplyr::filter( sponsor != "Unknown" )

  max_n <- max( dplyr::count( data.tib, sponsor )$n )
  len_n <- length( unique( data.tib$sponsor ) )

  g_bar <- data.tib |>
    ggplot2::ggplot() +
    ggplot2::geom_bar( position = ggplot2::position_stack( reverse = TRUE),
                       ggplot2::aes( y = sponsor, fill = year ) ) +
    ggplot2::geom_text( stat = "count", ggplot2::aes( y = sponsor, label = ggplot2::after_stat(count) ), hjust = -.5 ) +
    ggplot2::scale_fill_brewer( palette = "RdBu" ) +
    ggplot2::geom_point( data = share_data.tib,
                         ggplot2::aes( x = max(n) * 1.15, y = sponsor, size = share ),
                         shape = 21, fill = "lightblue", colour = "lightblue",
                         show.legend = FALSE ) +
    ggplot2::geom_text( data = share_data.tib,
                        ggplot2::aes( x = max(n) * 1.25 , y = sponsor, label = sprintf("%.1f%%", share*100) ),
                        colour = "navy", show.legend = FALSE ) +
    ggplot2::annotate( "text", x = max_n*0.5, y = len_n + 1, label = "Total Number of Publications" ) +
    ggplot2::annotate( "text", x = max_n*1.2 , y = len_n + 1, label = "Global Share" ) +
    ggplot2::scale_size_continuous( range = c( 0, 20 )) +
    ggplot2::scale_x_discrete( expand = c(0,0,0.10,0) ) +
    ggplot2::scale_y_discrete( expand = c(0,0,0,1.5) ) +
    ggplot2::theme_minimal() +
    ggplot2::labs( x = "Number and Global Share of Publications",
                   y = "Sponsor",
                   fill = "" ) +
    ggplot2::theme(
      legend.position = "inside",
      legend.position.inside = c(0.65, 0.5),
      legend.box = "vertical"
    )

  return( g_bar )
}
