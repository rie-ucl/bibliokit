#' Download Author Profiles
#'
#' The download_author_profiles() function retrieves detailed author profiles
#' from the existing Scopus Data
#'
#' @param res Scopus search results, including `entries`, which is a list of publication details.
#'   Each entry should have the fields `author`, where `author` is a list of authors.
#'   You can use the list of authids instead of a Scopus search result.
#'
#' @return A data frame containing detailed author profiles.
#'
#' @examples
#'
#' # Example 1
#' res <- list(
#'   meta_data = list(
#'     terms = "artificial intelligence"
#'   ),
#'   entries = list(
#'     list(
#'       author = list(
#'         list( `authid` = "24776780000" ),
#'         list( `authid` = "57940702100" )
#'       )
#'     )
#'   )
#' )
#' author_profiles <- download_author_profiles( res )
#'
#' @import rscopus
#' @export

download_author_profiles <- function( res ) {

  authid_list <-
    lapply( res$entries, function(e) {
      lapply( e$author, function(a) {
        if ( is.list(a) && length(a) > 0) {
          return( a$authid )
        } else {
          return(NULL)
        }
      })
    })

  authid_flat <- unique( unlist ( authid_list ) )

  au_complete_list <- list( authors = list(), get_statement = list() )
  total = length( authid_flat )

  for ( i in seq_along( authid_flat ) ) {
    au_info <- rscopus::get_complete_author_info( au_id = authid_flat[i] )
    au_complete_list$authors <- c( au_complete_list$authors, au_info$content$`search-results`$entry )
    if ( i %% 100 == 0 ) { print( total - i ) }
  }

  au_complete_list$get_statement <- au_info$get_statement


  save_file_name <- paste0( "author_list-", paste( res$meta_data$terms, collapse = "_" ) , "-",
                            format(Sys.Date(), "%y%m%d"), ".rda")
  save( au_complete_list, file = save_file_name )

}
