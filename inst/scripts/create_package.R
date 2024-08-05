library(usethis)
library(roxygen2)
library(devtools)

source("inst/scripts/generate_readme.R")
document()
build()
check()

# test_dir("tests/testthat")

# library(rscopus)

# use_r("hello")
# use_r("expand_queries")

# use_description( fields = list(
#   Title = "A Toolkit for Bibliometric Analysis",
#   Description = "A package for bibliometric analysis and data visualisation",
#   Author = "Rie Matsumoto",
#   Maintainer = "Rie Matsumoto <rie.hayashi.22@ucl.ac.uk>"
# ))
# use_mit_license( copyright_holder = "Rie Matsumoto" )

use_version( "major" )
use_version( "minor" )
use_version( "patch" )



#-----------------------------------------------------
library(testthat)
library(httptest)

source("R/expand_terms.R")
start_capturing()
result <- expand_terms("data analysis")
stop_capturing()
