#' Plot Author Number Trend
#'
#' This function analyzes the annual publication trends based on the number of authors
#' from Scopus search results, providing insights into how research collaboration
#' has changed over time according to the number of contributing authors.
#'
#' @param res Scopus search results, including `entries`, which is a list of publication details.
#'   Each entry should have the fields `dc:title` and `author`, where `author` is a list of authors.
#' @param type A string specifying the type of plot. Options are "line" (default), "stack", and "ratio".
#'   "line" produces a line plot, "stack" produces a stacked area plot, and "ratio" produces a 100% stacked area plot.
#' @return A ggplot2 object showing the trend analysis results over the years for each author number category.
#' @examples
#' # Create a sample `res` list to simulate Scopus API search results
#' res <- list(
#'   entries = list(
#'     list(
#'       `dc:title` = "A Study on Data Analysis",
#'       `prism:coverDate` = "2022-12-31",
#'       author = list(
#'         list( `authname` = "Author 1" ),
#'         list( `authname` = "Author 2" )
#'       )
#'     ),
#'     list(
#'       `dc:title` = "Advances in Machine Learning",
#'       `prism:coverDate` = "2021-11-30",
#'       author = list(
#'         list( `authname` = "Author 1" ),
#'         list( `authname` = "Author 2" ),
#'         list( `authname` = "Author 3" ),
#'         list( `authname` = "Author 4" ),
#'         list( `authname` = "Author 5" )
#'       )
#'     ),
#'     list(
#'       `dc:title` = "Research in Quantum Computing",
#'       `prism:coverDate` = "2020-10-15",
#'       author = list(
#'         list( `authname` = "Author 1" )
#'       )
#'     )
#'   )
#' )
#'
#' # Example usage of the function with the sample data
#' plot_authnum_trend( res, type = "stack" )
#'
#' @import utils
#' @import ggplot2
#' @import dplyr
#' @import tidyr
#' @import ggrepel
#' @import tools
#' @export

plot_authnum_trend <- function( res, type = "line" ) {
  entries <- res$entries

  # Extract year and author count from each entry
  data <- lapply( entries, function( entry ) {
    year <- substr( entry$`prism:coverDate`, 1, 4 )
    auth_count <- length( entry$author )
    if ( auth_count >= 10 ) {
      auth_count <- "10+"
    } else if ( auth_count >= 5 ) {
      auth_count <- "5-9"
    } else {
      auth_count <- as.character( auth_count )
    }
    list( year = year, auth_count = auth_count )
  })

  # Convert the extracted data into a tibble
  data.tib <- tibble::tibble(
    year = sapply( data, `[[`, "year" ),
    auth_count = sapply( data, `[[`, "auth_count" )
  )

  # Summarize the data by year and author count
  yearly_data.tib <- data.tib |>
    dplyr::group_by( year, auth_count ) |>
    dplyr::summarise( n = dplyr::n(), .groups = "drop" ) |>
    tidyr::complete( year, auth_count, fill = list( n = 0 ) ) |>
    dplyr::mutate( auth_count = factor( auth_count, levels = c( "10+", "5-9", "4", "3", "2", "1" ) ) )

  # Create the plot
  g <- yearly_data.tib |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = as.Date( paste0( year, "-01-01" ) ),
        y = n,
        fill = auth_count,
        colour = auth_count
      )
    )

  title <- tools::toTitleCase( paste(
    "Trends in Publications by Author Count (",
    bibliokit::get_search_terms( res ), ")" ) )
  if ( type == "stack" ) title <- paste( "Stacked", title )
  if ( type == "ratio" ) title <- paste( "Propotional", title )

  # Modify the plot based on the type
  if ( type == "line" ) {
    g <- g +
      ggplot2::geom_line( linewidth = 0.8, ggplot2::aes( group = auth_count ) ) +
      ggplot2::geom_point( size = 3, shape = 21, fill = "white" )
  } else if ( type == "stack" ) {
    g <- g + ggplot2::geom_area( position = "stack", alpha = 0.8 )
  } else if ( type == "ratio" ) {
    g <- g + ggplot2::geom_area( position = "fill", alpha = 0.8 ) +
      ggplot2::scale_y_continuous( labels = scales::percent_format() )
  }

  # Add common elements to the plot
  g <- g +
    ggplot2::scale_x_date( date_labels = "%Y", date_breaks = "1 year", expand = c( 0.02,0,0.02,0 ) ) +
    ggplot2::scale_colour_brewer( palette = "Dark2", aesthetics = c( "fill", "colour" ) ) +
    ggplot2::labs( x = "Year", y = ifelse( type == "ratio", "Percentage", "Number of Publications" ) ) +
    ggplot2::theme(
      panel.background = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line( colour = "WhiteSmoke" ),
      axis.ticks = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text( angle = 45, hjust = 1 )
    ) +
    ggplot2::labs( title = title )

  return( g )
}
