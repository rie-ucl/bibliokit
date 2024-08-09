#' Plot Sponsor Trend
#'
#' The `plot_sponsor_trend()` function analyses and visualizes
#' the annual publication trends for sponsors
#' from Scopus search results.
#'
#' @param res Scopus search results, including `entries`, which is a list of publication details.
#'   Each entry should have the fields `dc:title`, `prism:coverDate`, and `fund-sponsor` (with `fund-acr` for abbreviation).
#' @return A ggplot2 object showing the trend analysis results over the years for each sponsor.
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
#'       `prism:coverDate` = "2021-11-30",
#'       `fund-sponsor` = "China Scholarship Council",
#'       `fund-acr` = "CSC"
#'     ),
#'     list(
#'       `dc:title` = "Research in Quantum Computing",
#'       `prism:coverDate` = "2020-10-15",
#'       `fund-sponsor` = "German Research Foundation",
#'       `fund-acr` = "DFG"
#'     ),
#'     list(
#'       `dc:title` = "Innovations in AI",
#'       `prism:coverDate` = "2019-09-01",
#'       `fund-sponsor` = "Engineering and Physical Sciences Research Council",
#'       `fund-acr` = "EPSRC"
#'     ),
#'     list(
#'       `dc:title` = "Exploring New Frontiers in Science",
#'       `prism:coverDate` = "2018-08-01",
#'       `fund-sponsor` = NULL,
#'       `fund-acr` = NULL
#'     )
#'   )
#' )
#'
#' # Example usage of the function with the sample data
#' plot_sponsor_trend( res )
#'
#' @import ggplot2
#' @import dplyr
#' @import tidyr
#' @import ggrepel
#' @export

plot_sponsor_trend <- function( res ) {

  entries <- res$entries

  data <- lapply( entries, function( entry ) {
    title <- entry$`dc:title`
    year  <- substr( entry$`prism:coverDate`, 1, 4 )
    month <- substr( entry$`prism:coverDate`, 1, 7 )
    sponsor <- if ( !is.null(entry$`fund-sponsor`) && entry$`fund-sponsor` != "" ) {
      entry$`fund-sponsor`
    } else {
      "Unknown"
    }
    list( title = title, year = year, month = month, sponsor = sponsor )
  })

  data.tib <- tibble::tibble(
    title    = sapply( data, `[[`, "title" ),
    year     = sapply( data, `[[`, "year" ),
    month    = sapply( data, `[[`, "month" ),
    sponsor  = unlist( lapply( data, `[[`, "sponsor" ) )
  )

  top_sponsors <- data.tib |>
    dplyr::filter( sponsor != "Unknown" )  |>
    dplyr::count( sponsor, sort = TRUE ) |>
    utils::head( 5 ) |>
    dplyr::arrange( dplyr::desc(n) ) |>
    dplyr::pull( sponsor )

  latest_year <- ifelse(
    !is.null( res$meta_data ) && !is.null( res$meta_data$end_year ),
    res$meta_data$end_year,
    max( as.numeric( format( as.Date(
      sapply( res$entries, function(x) x$`prism:coverDate` ) ), "%Y" ) ), na.rm = TRUE )
  )

  latest_data.tib <- data.tib |>
    dplyr::filter( year == latest_year & sponsor %in% top_sponsors ) |>
    dplyr::count( sponsor, year )

  yearly_data.tib <- data.tib |>
    dplyr::group_by( year, sponsor ) |>
    dplyr::summarise( n = dplyr::n(), .groups = "drop" ) |>
    tidyr::complete( year, sponsor, fill = list( n = 0 ) ) |>
    dplyr::filter( sponsor %in% top_sponsors ) |>
    dplyr::mutate( sponsor = factor( sponsor, levels = top_sponsors ) )

  monthly_data.tib <- data.tib |>
    dplyr::group_by( month ) |>
    dplyr::summarise( n = dplyr::n(), .groups = "drop" )

  y_max <- max(yearly_data.tib |> dplyr::select(n), na.rm = TRUE)
  mag <- max(monthly_data.tib |> dplyr::select(n), na.rm = TRUE) / y_max - 0.2

  x_max <- max(as.numeric(yearly_data.tib$year))
  x_min <- min(as.numeric(yearly_data.tib$year))
  x_range <- x_max - x_min

  y2d <- function(y) {
    as.Date( paste0( round(y),"-01-01" ) )
  }

  (
    g_line <- yearly_data.tib |>
      ggplot2::ggplot(
        mapping = ggplot2::aes( x = as.Date( paste0( year,"-01-01" ) ),
                                y = n, group = sponsor, colour = sponsor ) ) +
      ggplot2::geom_area(
        data = monthly_data.tib, colour = "lightgray", fill = "lightgray",
        ggplot2::aes( x = as.Date( paste0( month,"-01" ) ), y = n/mag,
                      group = NA, colour = NA ), show.legend = FALSE ) +
      ggplot2::geom_line( linewidth = 0.8, show.legend = TRUE ) +
      ggplot2::geom_point( size = 3, shape = 21, fill = "white", show.legend = FALSE ) +
      ggrepel::geom_text_repel( ggplot2::aes( label = n ), vjust = -1, nudge_x = 0,
                                show.legend = FALSE, size = 3 ) +
      ggplot2::scale_x_date( date_labels = "%Y", date_breaks = "1 year",
                             expand = c(0.05,0,0.05,0) ) +
      ggplot2::scale_y_continuous( expand = c(0,0,0.05,0) ) +
      ggplot2::scale_colour_brewer( palette = "Set1" ) +
      ggplot2::labs( x = "Year", y = "Number of Publications" ) +
      ggplot2::theme(
        panel.background = ggplot2::element_blank(),
        panel.grid.major = ggplot2::element_line( colour = "WhiteSmoke" ),
        axis.ticks = ggplot2::element_blank(),
        axis.text.x = ggplot2::element_text( angle = 45, hjust = 1 ),
        legend.position = "inside",
        legend.position.inside = c(0.2,0.8),
        legend.direction = "vertical"
      )
  )

  return( g_line )
}
