#' Plot Country Pairs Collaboration Ratio
#'
#' The `plot_country_pairs_collaboration_ratio()` function analyses and visualizes
#' the annual publication trends for country pairs with their collaboration ratio
#' from Scopus search results.
#' You can filter the result with a target country by specifying `target_country`
#' and choose the `type` of the output from `line` or `stack`.
#'
#' @param res List structure containing publication data
#' @param n Number of top country pairs to plot (default is 5)
#' @param target_country Optional; specific country to filter the pairs by (default is NULL)
#' @param type Type of a graph
#' @return A plot object showing the trend of top country pairs by publication year
#' @export
#' @import dplyr
#' @import ggplot2
#' @import purrr
#' @import tidyr

plot_country_pairs_collaboration_ratio <- function(res, n = 5, target_country = NULL, type = "line") {
  country_pairs <- purrr::map_df(res$entries, function(entry) {
    countries <- entry$affiliation |>
      purrr::map( ~ .x$`affiliation-country` ) |>
      unlist() |>
      na.omit() |>
      unique()
    if (length(countries) < 2) {
      return(data.frame(year = character(), pair = character()))
    }
    pairs <- combn(countries, 2, simplify = FALSE)
    data.frame(
      year = substr(entry$`prism:coverDate`, 1, 4),
      pair = purrr::map_chr(pairs, ~ paste(sort(.x), collapse = "-"))
    )
  })

  if (!is.null(target_country)) {
    country_pairs <- country_pairs |>
      dplyr::filter(grepl(target_country, pair))
  }

  filtered_data <- country_pairs |>
    dplyr::count(year, pair) |>
    tidyr::complete(year, pair, fill = list(n = 0))

  total_publications_per_year <- filtered_data |>
    dplyr::group_by(year) |>
    dplyr::summarise(total_publications = sum(n))

  filtered_data <- filtered_data |>
    dplyr::left_join(total_publications_per_year, by = "year") |>
    dplyr::mutate(collaboration_ratio = (n / total_publications) * 100)

  top_pairs <- filtered_data |>
    dplyr::group_by(pair) |>
    dplyr::summarise(total_count = sum(n)) |>
    dplyr::arrange(desc(total_count)) |>
    dplyr::slice_head(n = n) |>
    dplyr::pull(pair)

  filtered_data <- filtered_data |>
    dplyr::filter(pair %in% top_pairs)

  p <- ggplot2::ggplot(filtered_data, ggplot2::aes(x = year, y = collaboration_ratio, color = pair, group = pair)) +
    ggplot2::labs(title = "Top Country Pairs by Collaboration Ratio (%)", x = "Year", y = "Collaboration Ratio (%)") +
    ggplot2::theme_minimal()

  if (type == "stack") {
    p <- p +
      ggplot2::geom_area(position = "stack", alpha = 0.6) +
      ggplot2::scale_y_continuous(labels = scales::percent_format(scale = 1))
  } else {
    p <- p +
      ggplot2::geom_line(linewidth = 1) +
      ggplot2::geom_point(size = 3, shape = 21, fill = "white") +
      ggplot2::geom_text(ggplot2::aes(label = sprintf("%.1f%%", collaboration_ratio)), vjust = -0.6, size = 3, show.legend = FALSE)
  }

  return(p)
}
