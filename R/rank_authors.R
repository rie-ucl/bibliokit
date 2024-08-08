#' Rank Authors by Number of Publications and Citations
#'
#' The `rank_authors()` function generates a ranking of the top authors
#' from the provided Scopus search results,
#' based on the number of publications and total citations.
#' By setting the `include_all = TRUE` option, the function can include
#' not only the first authors but also all authors of the publications in the ranking.
#' The output is a tibble with the following columns:
#' `rank` rank of the author,
#' `name` author's name,
#' `n_publications` number of publications,
#' `n_citations` total number of citations,
#' `institution` author's primary institution, and
#' `country` author's country.
#'
#' @param res A list containing Scopus search results.
#' @param n An integer specifying the number of top authors to return. Defaults to 20.
#' @param include_all A logical value indicating whether to include secondary authors. Defaults to FALSE.
#'
#' @return A tibble with the ranking of authors.
#' @examples
#' res <- list(
#'   entries = list(
#'     list(author = list(
#'          list(authid = "012345", authname = "Smith J.",
#'               affiliation = list(list(`affilname` = "University A",
#'                                       `affiliation-country` = "Country A"))),
#'          list(authid = "333333", authname = "Doe J.",
#'               affiliation = list(list(`affilname` = "University B",
#'                                       `affiliation-country` = "Country B")))),
#'          `citedby-count` = 10, `prism:coverDate` = "2024-12-01"),
#'     list(author = list(
#'          list(authid = "012345", authname = "Smith J.",
#'               affiliation = list(list(`affilname` = "University A",
#'                                       `affiliation-country` = "Country A"))),
#'          list(authid = "987654", authname = "Brown S.",
#'               affiliation = list(list(`affilname` = "University C",
#'                                       `affiliation-country` = "Country C")))),
#'          `citedby-count` = 5, `prism:coverDate` = "2020-12-01")
#'   )
#' )
#' rank_authors(res, n = 20, include_all = FALSE)
#'
#' @import utils
#'
#' @export

rank_authors <- function(res, n = 20, include_all = FALSE) {

  authors_data <- unlist(lapply(res$entries, function(entry) {
    authors <- entry$author

    if (is.null(authors) || length(authors) == 0) return(NULL)
    if (!is.list(authors[[1]])) authors <- list(authors)

    authors[[1]]$affiliation <- entry$affiliation
    coverDate <- res$entries[[1]]$`prism:coverDate`

    if (include_all) {
      lapply( authors, function(author) {
        list(
          id = author$authid,
          name = author$authname,
          n_citations = as.numeric( entry$`citedby-count` ),
          institution = ifelse(!is.null(author$affiliation[[1]]$`affilname`), author$affiliation[[1]]$`affilname`, NA),
          country = ifelse(!is.null(author$affiliation[[1]]$`affiliation-country`),
                           author$affiliation[[1]]$`affiliation-country`, NA),
          date = coverDate
        )
      })
    } else {
      list(
        list(
          id = authors[[1]]$authid,
          name = authors[[1]]$authname,
          n_citations = as.numeric( entry$`citedby-count` ),
          institution = ifelse(!is.null(authors[[1]]$affiliation[[1]]$`affilname`), authors[[1]]$affiliation[[1]]$`affilname`, NA),
          country = ifelse(!is.null(authors[[1]]$affiliation[[1]]$`affiliation-country`),
                           authors[[1]]$affiliation[[1]]$`affiliation-country`, NA),
          date = coverDate
        )
      )
    }
  }), recursive = FALSE)

  authors_tibble <- dplyr::bind_rows(authors_data)

  authors_list <- authors_tibble |>
    dplyr::group_by( id ) |>
    dplyr::arrange( dplyr::desc( date ) ) |>
    dplyr::summarise(
      name = dplyr::first( name[!is.na( name )] ),
      institution = dplyr::first( institution[!is.na( institution )] ),
      country = dplyr::first( country[!is.na( country )] ),
      .groups = 'drop'
    ) |>
    dplyr::select( id, name, institution, country )

  author_rankings <- authors_tibble |>
    dplyr::group_by( id ) |>
    dplyr::summarise(
      n_publications = dplyr::n(),
      n_citations = sum(n_citations, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::filter( !is.na( id ) ) |>
    dplyr::arrange( dplyr::desc(n_publications), dplyr::desc(n_citations) ) |>
    dplyr::mutate(rank = dplyr::row_number(), .before = 1) |>
    utils::head(n)

  author_rankings <- author_rankings |>
    dplyr::left_join( authors_list, by = dplyr::join_by("id") ) |>
    dplyr::select( rank, id, name, n_publications, n_citations, institution, country )

  return( author_rankings )
}
