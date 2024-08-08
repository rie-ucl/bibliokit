#' Rank Sponsors by Number of Publications and Citations
#'
#' The `rank_sponsors()` function generates a ranking of the top sponsors
#' from the provided Scopus search results,
#' based on the number of publications and total citations.
#' The output is a tibble with the following columns:
#' `rank` rank of the sponsor,
#' `sponsor` sponsor's name with abbreviation,
#' `n_publications` number of publications,
#' `n_citations` total number of citations,
#' `cite_per_pub` average number of citations per publication,
#' `countries_display` comma-separated list of countries where the sponsor is active, and
#' `countries` list of countries where the sponsor is active.
#'
#' @param res A list containing Scopus search results.
#' @param n An integer specifying the number of top sponsors to return. Defaults to 20.
#'
#' @return A tibble with the ranking of sponsors.
#' @examples
#' res <- list(
#'   entries = list(
#'     list(`fund-sponsor` = "Youth Innovation Promotion Association",
#'          `fund-acr` = "YIPA",
#'          affiliation = list(list(`affiliation-country` = c("Country A", "Country B"))),
#'          `citedby-count` = 10),
#'     list(`fund-sponsor` = "National Science Foundation",
#'          `fund-acr` = "NSF",
#'          affiliation = list(list(`affiliation-country` = c("Country C"))),
#'          `citedby-count` = 5)
#'   )
#' )
#' rank_sponsors(res, n = 20)
#'
#' @import utils
#'
#' @export

rank_sponsors <- function( res, n = 10 ) {

  sponsors_data <- lapply( res$entries, function( entry ) {
    sponsor <- entry$`fund-sponsor`
    acronym <- entry$`fund-acr`

    if ( is.null( sponsor ) ) return( NULL )

    list(
      sponsor = ifelse( !is.null( acronym ) && acronym != "",
                        paste( sponsor, " (", acronym, ")", sep = "" ),
                        sponsor ),
      n_citations = as.numeric( entry$`citedby-count` ),
      country = entry$affiliation[[1]]$`affiliation-country`
    )
  })

  sponsors_data <- sponsors_data[ !sapply( sponsors_data, is.null ) ]

  sponsors_tibble <- dplyr::bind_rows( sponsors_data )

  sponsors_ranking <- sponsors_tibble |>
    dplyr::group_by( sponsor, country ) |>
    dplyr::summarise( n_per_country = dplyr::n(),
                      n_citations = sum( n_citations ) ) |>
    dplyr::arrange( dplyr::desc( n_per_country ) ) |>
    dplyr::mutate( country_with_num = paste0( country, "(", n_per_country, ")" ) ) |>
    dplyr::group_by( sponsor ) |>
    dplyr::summarise(
      n_publications = sum( n_per_country ),
      n_citations = sum( n_citations ),
      cite_per_pub = n_citations / n_publications,
      n_countries = dplyr::n(),
      country_list = list( country ),
      country_disp = list( country_with_num )
    ) |>
    dplyr::arrange( dplyr::desc( n_publications ) ) |>
    dplyr::mutate(
      rank = dplyr::row_number(),
      country_display = sapply( country_disp, function(x) paste0( utils::head(x,5), collapse = ", " ) )
    ) |>
    dplyr::select(
      rank, sponsor, n_publications, n_citations, cite_per_pub, n_countries, country_display, country_list
    ) |>
    utils::head( n )

  return( sponsors_ranking )
}
