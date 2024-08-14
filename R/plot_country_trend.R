#' Plot Country Trend
#'
#' The `plot_country_trend()` function analyses and visualizes
#' the annual publication trends for countries
#' from Scopus search results.
#'
#' @param res Scopus search results, including `entries`, which is a list of publication details.
#'   Each entry should have the fields `dc:title`, `prism:coverDate`, and `affiliation`
#'   (with `affiliation-country`).
#' @return A ggplot2 object showing the trend analysis results over the years for each country.
#' @examples
#' # Create a sample `res` list to simulate Scopus API search results
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
#'       `prism:coverDate` = "2021-11-30",
#'       affiliation = list(
#'         list(
#'           `affiliation-country` = "China"
#'         )
#'       )
#'     ),
#'     list(
#'       `dc:title` = "Research in Quantum Computing",
#'       `prism:coverDate` = "2020-10-15",
#'       affiliation = list(
#'         list(
#'           `affiliation-country` = "Germany"
#'         )
#'       )
#'     ),
#'     list(
#'       `dc:title` = "Innovations in AI",
#'       `prism:coverDate` = "2019-09-01",
#'       affiliation = list(
#'         list(
#'           `affiliation-country` = "United Kingdom"
#'         )
#'       )
#'     ),
#'     list(
#'       `dc:title` = "Exploring New Frontiers in Science",
#'       `prism:coverDate` = "2018-08-01",
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
#' plot_country_trend( res )
#'
#' @import utils
#'
#' @export


plot_country_trend <- function( res ) {

  entries <- res$entries

  data <- lapply( entries, function( entry ) {
    title <- entry$`dc:title`
    year  <- substr( entry$`prism:coverDate`, 1, 4 )
    month <- substr( entry$`prism:coverDate`, 1, 7 )
    country <- if ( !is.null(entry$affiliation[[1]]$`affiliation-country`) ) {
      entry$affiliation[[1]]$`affiliation-country`
    } else {
      "Unknown"
    }
    list( title = title, year = year, month = month, country = country )
  })

  data.tib <- tibble::tibble(
    title   = sapply( data, `[[`, "title" ),
    year    = sapply( data, `[[`, "year" ),
    month   = sapply( data, `[[`, "month" ),
    country = unlist( lapply( data, `[[`, "country" ) )
  )

  top_countries <- data.tib |>
    dplyr::filter( country != "Unknown" )  |>
    dplyr::count( country, sort = TRUE ) |>
    utils::head( 5 ) |>
    dplyr::arrange( dplyr::desc(n) ) |>
    dplyr::pull( country )

  latest_year <- ifelse(
    !is.null( res$meta_data ) && !is.null( res$meta_data$end_year ),
    res$meta_data$end_year,
    max( as.numeric( format( as.Date(
      sapply( res$entries, function(x) x$`prism:coverDate` ) ), "%Y" ) ), na.rm = TRUE )
  )

  latest_data.tib <- data.tib |>
    dplyr::filter( year == latest_year & country %in% top_countries ) |>
    dplyr::count( country, year )

  yearly_data.tib <- data.tib |>
    dplyr::group_by( year, country ) |>
    dplyr::summarise( n = dplyr::n(), .groups = "drop" ) |>
    tidyr::complete( year, country, fill = list( n = 0 ) ) |>
    dplyr::filter( country %in% top_countries ) |>
    dplyr::mutate( country = factor( country, levels = top_countries ) )

  monthly_data.tib <- data.tib |>
    dplyr::group_by( month ) |>
    dplyr::summarise( n = dplyr::n(), .groups = "drop" )

  y_max <- max(yearly_data.tib |> dplyr::select(n))
  mag <- max(monthly_data.tib |> dplyr::select(n)) / y_max - 0.2

  x_max <- max(as.numeric(yearly_data.tib$year))
  x_min <- min(as.numeric(yearly_data.tib$year))
  x_range <- x_max - x_min

  y2d <- function(y) {
            as.Date( paste0( round(y),"-01-01" ) )
          }

  (
  g_line <- yearly_data.tib |>
    ggplot2::ggplot(
      mapping = ggplot2::aes( x = as.Date(paste0(year,"-01-01")),
                              y = n, group = country, colour = country ) ) +
      ggplot2::geom_area(
        data = monthly_data.tib, fill = "lightgray",
        ggplot2::aes( x = as.Date(paste0(month,"-01")), y = n/mag,
                      group = NA, colour = NA ), show.legend = FALSE ) +
      ggplot2::geom_label( label = "Total number of publications",
                           label.r = ggplot2::unit(0, "lines"), label.size = 0,
                           fill = "lightgray", colour = "white",
                           x = y2d(x_min+x_range*0.03), y = y_max*0.97, hjust = 0 ) +
      ggplot2::geom_line( linewidth = 0.8, show.legend = FALSE ) +
      ggplot2::geom_point( size = 3, shape = 21, fill = "white", show.legend = FALSE ) +
      ggrepel::geom_label_repel(
        data = latest_data.tib,
        ggplot2::aes( label = country, y = n, fill = country),
        size = 3, fontface = "bold", colour = "white", label.r = 0,
        hjust = 0, nudge_x = x_range*20, direction = "y", seed = 42,
        segment.color = NA, show.legend = FALSE ) +
      ggrepel::geom_text_repel(
        ggplot2::aes( label = n ), vjust = -1, nudge_x = 0,
        show.legend = FALSE, size = 3 ) +
      ggplot2::scale_x_date( date_labels = "%Y", date_breaks = "1 year",
                             expand = c(0.05,0,0.2,0) ) +
      ggplot2::scale_y_continuous( expand = c(0,0,0.05,0) ) +
      ggplot2::scale_colour_brewer( palette = "Set1", aesthetics = c("fill","colour") ) +
      ggplot2::labs( x = "Year", y = "Number of Publications" ) +
      ggplot2::theme(
        panel.background = ggplot2::element_blank(),
        panel.grid.major = ggplot2::element_line( colour = "WhiteSmoke" ),
        axis.ticks = ggplot2::element_blank(),
        axis.text.x = ggplot2::element_text( angle = 45, hjust = 1 )
      )
  )

  return( g_line )
}
