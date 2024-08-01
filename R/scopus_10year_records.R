#' Scopus 10 Year Records
#'
#' This function retrieves bibliographic records from the Scopus API for the past 10 years.
#'
#' @param terms A character vector of search terms (e.g., "machine learning" or c("machine learning", "algorithm")). These terms will be used to search for bibliographic records in the Scopus database.
#' @param search_type A character string specifying the search field. The default is "TITLE-ABS-KEY", which searches within titles, abstracts, and keywords. Other options can be specified as needed.
#' @param other_fields A character vector of additional search fields to include in the query.
#'                     Each entry should be a string representing a field condition, such as "AND AUTHOR-NAME(smith)".
#'                     These will be appended to the base query. Default is an empty string (""), meaning no additional fields.
#'                     Example: c("AND AUTHOR-NAME(smith)", "AND AFFILORG(University)").
#' @param save_dir A string specifying the directory where the results file will be saved.
#'                 If the directory does not exist, it will be created. Default is "bibdata".
#'
#' @return A data frame containing bibliographic records for the past 10 years. The data frame includes various fields such as titles, authors, and other relevant metadata from the Scopus database. The specific columns in the data frame may vary depending on the search results.
#'
#' @examples
#' # Example 1: Search for records related to "machine learning"
#' entries <- scopus_10year_records( "journalist robot", search_type = "TITLE" )
#'
#' # Example 2: Search for records related to multiple terms
#' terms <- c("machine learning", "algorithm")
#' entries <- scopus_10year_records( terms, other_fields = "AND AUTHOR-NAME(matsumoto)" )
#' head(entries)
#'
#' @import rscopus
#' @export

scopus_10year_records <- function(terms, search_type = "TITLE-ABS-KEY", other_fields = "", save_dir = "bibdata" ) {

  allowed_search_types <- c(
    "ALL",
    "ABS",
    "AF-ID",
    "AFFIL",
    "AFFILCITY",
    "AFFILCOUNTRY",
    "AFFILORG",
    "ARTNUM",
    "AU-ID",
    "AUTHOR-NAME",
    "AUTH",
    "AUTHFIRST",
    "AUTHLASTNAME",
    "AUTHCOLLAB",
    "AUTHKEY",
    "CASREGNUMBER",
    "CHEM",
    "CHEMNAME",
    "CODEN",
    "CONF",
    "CONFLOC",
    "CONFNAME",
    "CONFSPONSORS",
    "DOCTYPE",
    "DOI",
    "EDFIRST",
    "EDITOR",
    "EDLASTNAME",
    "EISSN",
    "EXACTSRCTITLE",
    "FIRSTAUTH",
    "FUND-SPONSOR",
    "FUND-ACR",
    "FUND-NO",
    "INDEXTERMS",
    "ISBN",
    "ISSN",
    "ISSNP",
    "ISSUE",
    "KEY",
    "LANGUAGE",
    "MANUFACTURER",
    "PAGEFIRST",
    "PAGELAST",
    "PAGES",
    "PMID",
    "PUBDATETXT",
    "PUBYEAR",
    "REF",
    "REFAUTH",
    "REFTITLE",
    "REFSRCTITLE",
    "REFPUBYEAR",
    "REFARTNUM",
    "REFPAGE",
    "REFPAGEFIRST",
    "SEQBANK",
    "SEQNUMBER",
    "SRCTITLE",
    "SRCTYPE",
    "SUBJAREA",
    "TITLE",
    "TITLE-ABS-KEY",
    "TITLE-ABS-KEY-AUTH",
    "TRADENAME",
    "VOLUME",
    "WEBSITE"
  )

  if ( !search_type %in% allowed_search_types ) {
    stop( paste("Invalid search type:", search_type ) )
  }

  base_query = paste( search_type, "(", paste0('"', terms, '"', collapse = ' AND '), ")", other_fields )

  current_year = as.integer( format( Sys.time(), "%Y") )

  get_total_results <- function( query ) {
    result <- rscopus::scopus_search( query = query, view = "STANDARD", count = 1, max_count = 1 )
    return( result$total_results )
  }

  combined_entries <- list()

  for ( y in seq( current_year, current_year-10 ) ) {
    year_query <- paste( base_query, "AND PUBYEAR =", y )
    total_results <- get_total_results( year_query )

    if( total_results > 5000 ){
      for ( m in 1:12 ){
        month_query <- paste( base_query, "AND PUBDATETXT(", month.name[m], y, ")" )
        total_results_month <- get_total_results( month_query )

        if ( total_results_month > 5000 ) {
          stop( "Too many results even when split by month. Re-consider search terms.")
        }

        res <- rscopus::scopus_search(
          query = month_query,
          view = "COMPLETE",
          count = 25,
          max_count = 5000
        )

        combined_entries <- c( combined_entries, res$entries )
      }
    } else {
      res <- rscopus::scopus_search(
        query = year_query,
        view = "COMPLETE",
        count = 25,
        max_count = 5000
      )
      combined_entries <- c( combined_entries, res$entries )
    }
  }

  res <- list (
    entries = combined_entries,
    meta_data = c(
      search_type = search_type,
      terms = list( terms ),
      query = base_query,
      start_year = current_year - 10,
      end_year = current_year,
      search_time = Sys.time(),
      total_results = length(combined_entries)
    ),
    get_statements = res$get_statements
  )

  if (!dir.exists( save_dir ) ) {
    dir.create( save_dir, recursive = TRUE )
  }
  save_file_name <- paste0("rscopus-", format(Sys.Date(), "%Y_%m_%d"), "-", gsub(" ", "_", terms[1]), ".rda")
  save_path <- file.path( save_dir, save_file_name )
  save( res, file = save_path )

  return( res )

}
