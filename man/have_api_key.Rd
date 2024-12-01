% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/have_api_key.R
\name{have_api_key}
\alias{have_api_key}
\title{Check Scopus API Key}
\usage{
have_api_key()
}
\value{
A logical vector.
}
\description{
To use the Bibliokit library, you need a Scopus API account.
If you have not set up your API key yet, you need to sign up
your Scopus API account and set it up for your device.
Follow the instruction of \code{rscopus} library.
By using have_apr_key() function (a simple wrapper of the
same-name function of \code{rscopus} library), you can check
if you already have a proper API key.
}
\examples{
have_api_key()

}
