#' Check Scopus API Key
#'
#' To use the Bibliokit library, you need a Scopus API account.
#' If you have not set up your API key yet, you need to sign up
#' your Scopus API account and set it up for your device.
#' Follow the instruction of `rscopus` library.
#' By using have_apr_key() function (a simple wrapper of the
#' same-name function of `rscopus` library), you can check
#' if you already have a proper API key.
#'
#' @return A logical vector.
#'
#' @examples
#' have_api_key()
#'
#' @import rscopus
#'
#' @export

have_api_key <- function() {
  return( rscopus::have_api_key() )
}
