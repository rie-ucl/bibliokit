# bibliokit

## DESCRIPTION

This package offers tools for analyzing and visualizing bibliometric data from academic literature. It includes functions for extracting and processing citation data, generating keyword co-occurrence networks, and producing authorand publication statistics. The package aims to assist researchers in exploring trends and patterns in scientific publications.

- License: GPL-3
- Encoding: UTF-8
- RoxygenNote: 7.3.1
### Imports
-    utils (>= 4.3.2)
-  httr (>= 1.4.7)
-  readr (>= 2.1.4)
-  stringr (>= 1.5.1)
-  dplyr (>= 1.1.4)
-  tidyr (>= 1.3.1)
-  tibble (>= 3.2.1)
-  ggplot2 (>= 3.5.0)
-  ggrepel (>= 0.9.5)
-  igraph (>= 2.0.3)
-  ggraph (>= 2.2.0)
-  purrr (>= 1.0.2)
-  rscopus (>= 0.7.2)
-  litsearchr (>= 1.0.0)
-  knitr (>= 1.45)
-  rmarkdown (>= 2.25) VignetteBuilder: knitr

## download_scopus_data.R

Download Scopus Data

The download_scopus_data() function retrieves bibliographic records from
the Scopus API for the past N years.

### Parameter
 terms A character vector of search terms (e.g., "machine learning" or c("machine learning", "algorithm")). These terms will be used to search for bibliographic records in the Scopus database.
### Parameter
 n A integer specifying the search period. The default is "10".
### Parameter
 search_type A character string specifying the search field. The default is "TITLE-ABS-KEY", which searches within titles, abstracts, and keywords. Other options can be specified as needed.
### Parameter
 other_fields A character vector of additional search fields to include in the query.
Each entry should be a string representing a field condition, such as "AND AUTHOR-NAME(smith)".
These will be appended to the base query. Default is an empty string (""), meaning no additional fields.
Example: c("AND AUTHOR-NAME(smith)", "AND AFFILORG(University)").
### Parameter
 save_dir A string specifying the directory where the results file will be saved.
If the directory does not exist, it will be created. Default is "bibdata".

### Returned value
 A data frame containing bibliographic records for the past 10 years (or n years, if you specify). The data frame includes various fields such as titles, authors, and other relevant metadata from the Scopus database. The specific columns in the data frame may vary depending on the search results.

### Example usage of the function with the sample data
```r

# Example 1: Search for records related to "machine learning"
entries <- download_scopus_data( "journalist robot", search_type = "TITLE" )

# Example 2: Search for records related to multiple terms
terms <- c("machine learning", "algorithm")
entries <- download_scopus_data( terms, other_fields = "AND AUTHOR-NAME(matsumoto)" )
head(entries)

```
### Imported libraries
 rscopus



## expand_search_terms.R

Expand Search Terms

The `expand_search_terms()` function takes one or more initial search terms and
returns a query (expanded set of terms) by including related or similar terms.
The expansion helps to capture more relevant results by broadening the search.

### Parameter
 naive_terms A character vector of one or more initial search queries.
### Returned value
 A character vector containing the original queries along with expanded search terms.
### Example usage of the function with the sample data
```r

expand_search_terms( c( "data analysis", "machine learning" ) )

```
### Imported libraries
 utils




## get_search_query.R

Extract the search query from a given URL.

This function extracts the search query string from a URL containing
Scopus API search parameters.

### Parameter
 res A list containing Scopus search results, with a URL field in `get_statements`.
### Returned value
 A character string containing the search query.
### Example usage of the function with the sample data
```r

res <- list(
get_statements = list(
url = "https://api.elsevier.com/content/search/scopus?query=TITLE-ABS-KEY%20%28%22artificial%20intelligence%22%20AND%20%22national%20security%22%20OR%20%22machine%20learning%22%29"
)
)
#' get_search_query( res )

```
### Imported libraries
 utils




## get_search_terms.R

Extract search terms from a Scopus search URL.

This function extracts search keywords and other query parameters from the provided Scopus search URL
within the `res` object. The URL is obtained from `res$get_statements$url`.

### Parameter
 res A list containing Scopus search results, with a URL field in `get_statements`.
### Returned value
 A list containing the search keywords and other query parameters.

### Example usage of the function with the sample data
```r

res <- list(
get_statements = list(
url = "https://api.elsevier.com/content/search/scopus?query=TITLE-ABS-KEY%20%28%20%22oryza%20sativa%22%20%29%20%20AND%20PUBYEAR%20%3D%202014&count=25&start=0&view=COMPLETE"
)
)
get_search_terms(res)

```
### Imported libraries
 utils




## have_api_key.R

Check Scopus API Key

To use the Bibliokit library, you need a Scopus API account.
If you have not set up your API key yet, you need to sign up
your Scopus API account and set it up for your device.
Follow the instruction of `rscopus` library.
By using have_apr_key() function (a simple wrapper of the
same-name function of `rscopus` library), you can check
if you already have a proper API key.

### Returned value
 A logical vector.

### Example usage of the function with the sample data
```r

have_api_key()

```
### Imported libraries
 rscopus




## plot_authnum_trend.R

Plot Author Number Trend

The `plot_authnum_trend()` function analyses and visualizes
the annual publication trends for the number of authors
from Scopus search results.
You can specify `type` of the output from `line`, `stack` and `ratio`.

### Parameter
 res Scopus search results, including `entries`, which is a list of publication details.
Each entry should have the fields `dc:title` and `author`, where `author` is a list of authors.
### Parameter
 type A string specifying the type of plot. Options are "line" (default), "stack", and "ratio".
"line" produces a line plot, "stack" produces a stacked area plot, and "ratio" produces a 100% stacked area plot.
### Returned value
 A ggplot2 object showing the trend analysis results over the years for each author number category.
### Example usage of the function with the sample data
```r

# Create a sample `res` list to simulate Scopus API search results
res <- list(
entries = list(
list(
`dc:title` = "A Study on Data Analysis",
`prism:coverDate` = "2022-12-31",
author = list(
list( `authname` = "Author 1" ),
list( `authname` = "Author 2" )
)
),
list(
`dc:title` = "Advances in Machine Learning",
`prism:coverDate` = "2021-11-30",
author = list(
list( `authname` = "Author 1" ),
list( `authname` = "Author 2" ),
list( `authname` = "Author 3" ),
list( `authname` = "Author 4" ),
list( `authname` = "Author 5" )
)
),
list(
`dc:title` = "Research in Quantum Computing",
`prism:coverDate` = "2020-10-15",
author = list(
list( `authname` = "Author 1" )
)
)
)
)

# Example usage of the function with the sample data
plot_authnum_trend( res, type = "stack" )

```
### Imported libraries
 utils
```
### Imported libraries
 ggplot2
```
### Imported libraries
 dplyr
```
### Imported libraries
 tidyr
```
### Imported libraries
 ggrepel
```
### Imported libraries
 tools



## plot_country_overview.R

Plot Country Overview

The `plot_country_overview()` function analyses and visualise
the countries associated with publications
from Scopus search results.

### Parameter
 res Scopus search results, including `entries`, which is a list of publication details.
Each entry should have the fields `dc:title`, `prism:coverDate`, and `affiliation`
(with `affiliation-country`).

### Returned value
 A ggplot2 object showing the analysis results.

### Example usage of the function with the sample data
```r

res = list(
entries = list(
list(
`dc:title` = "A Study on Data Analysis",
`prism:coverDate` = "2022-12-31",
affiliation = list(
list(
`affiliation-country` = "United States"
)
)
),
list(
`dc:title` = "Advances in Machine Learning",
`prism:coverDate` = "2022-11-30",
affiliation = list(
list(
`affiliation-country` = "China"
)
)
),
list(
`dc:title` = "Research in Quantum Computing",
`prism:coverDate` = "2022-10-15",
affiliation = list(
list(
`affiliation-country` = "Germany"
)
)
),
list(
`dc:title` = "Innovations in AI",
`prism:coverDate` = "2022-09-01",
affiliation = list(
list(
`affiliation-country` = "United Kingdom"
)
)
),
list(
`dc:title` = "Exploring New Frontiers in Science",
`prism:coverDate` = "2022-08-01",
affiliation = list(
list(
`affiliation-country` = NULL
)
)
)
)
)

plot_country_overview( res )

```
### Imported libraries
 utils
```
### Imported libraries
 dplyr




## plot_country_pairs_collaboration_ratio.R

Plot Country Pairs Collaboration Ratio

The `plot_country_pairs_collaboration_ratio()` function analyses and visualizes
the annual publication trends for country pairs with their collaboration ratio
from Scopus search results.
You can filter the result with a target country by specifying `target_country`
and choose the `type` of the output from `line` or `stack`.

### Parameter
 res List structure containing publication data
### Parameter
 n Number of top country pairs to plot (default is 5)
### Parameter
 target_country Optional; specific country to filter the pairs by (default is NULL)
### Parameter
 type Type of a graph
### Returned value
 A plot object showing the trend of top country pairs by publication year

```
### Imported libraries
 dplyr
```
### Imported libraries
 ggplot2
```
### Imported libraries
 purrr
```
### Imported libraries
 tidyr




## plot_country_pairs_trend.R

Plot Country Pairs Trend

The `plot_country_pairs_trend()` function analyses and visualizes
the annual publication trends for country pairs
from Scopus search results.
You can filter the result with a target country by specifying `target_country`.

### Parameter
 res List structure containing publication data
### Parameter
 n Number of top country pairs to plot (default is 5)
### Parameter
 target_country Optional; specific country to filter the pairs by (default is NULL)
### Returned value
 A plot object showing the trend of top country pairs by publication year

```
### Imported libraries
 dplyr
```
### Imported libraries
 ggplot2
```
### Imported libraries
 purrr
```
### Imported libraries
 tidyr


## plot_country_trend.R

Plot Country Trend

The `plot_country_trend()` function analyses and visualizes
the annual publication trends for countries
from Scopus search results.

### Parameter
 res Scopus search results, including `entries`, which is a list of publication details.
Each entry should have the fields `dc:title`, `prism:coverDate`, and `affiliation`
(with `affiliation-country`).
### Returned value
 A ggplot2 object showing the trend analysis results over the years for each country.
### Example usage of the function with the sample data
```r

# Create a sample `res` list to simulate Scopus API search results
res = list(
entries = list(
list(
`dc:title` = "A Study on Data Analysis",
`prism:coverDate` = "2022-12-31",
affiliation = list(
list(
`affiliation-country` = "United States"
)
)
),
list(
`dc:title` = "Advances in Machine Learning",
`prism:coverDate` = "2021-11-30",
affiliation = list(
list(
`affiliation-country` = "China"
)
)
),
list(
`dc:title` = "Research in Quantum Computing",
`prism:coverDate` = "2020-10-15",
affiliation = list(
list(
`affiliation-country` = "Germany"
)
)
),
list(
`dc:title` = "Innovations in AI",
`prism:coverDate` = "2019-09-01",
affiliation = list(
list(
`affiliation-country` = "United Kingdom"
)
)
),
list(
`dc:title` = "Exploring New Frontiers in Science",
`prism:coverDate` = "2018-08-01",
affiliation = list(
list(
`affiliation-country` = NULL
)
)
)
)
)

# Example usage of the function with the sample data
plot_country_trend( res )

```
### Imported libraries
 utils




## plot_sponsor_overview.R

Plot Sponsor Overview

The `plot_sponsor_overview()` function analyses and visualise
the sponsors from Scopus search results..

### Parameter
 res Scopus search results, including `entries`, which is a list of publication details.
Each entry should have the fields `dc:title`, `prism:coverDate`, and `fund-sponsor` (with `fund-acr` for abbreviation).

### Returned value
 A ggplot2 object showing the analysis results.

### Example usage of the function with the sample data
```r

# Create a sample `res` list to simulate Scopus API search results
res = list(
entries = list(
list(
`dc:title` = "A Study on Data Analysis",
`prism:coverDate` = "2022-12-31",
`fund-sponsor` = "National Science Foundation",
`fund-acr` = "NSF"
),
list(
`dc:title` = "Advances in Machine Learning",
`prism:coverDate` = "2022-11-30",
`fund-sponsor` = "China Scholarship Council",
`fund-acr` = "CSC"
),
list(
`dc:title` = "Research in Quantum Computing",
`prism:coverDate` = "2022-10-15",
`fund-sponsor` = "German Research Foundation",
`fund-acr` = "DFG"
),
list(
`dc:title` = "Innovations in AI",
`prism:coverDate` = "2022-09-01",
`fund-sponsor` = "Engineering and Physical Sciences Research Council",
`fund-acr` = "EPSRC"
),
list(
`dc:title` = "Exploring New Frontiers in Science",
`prism:coverDate` = "2022-08-01",
`fund-sponsor` = NULL,
`fund-acr` = NULL
)
)
)

# Example usage of the function with the sample data
plot_sponsor_overview( res )

```
### Imported libraries
 dplyr
```
### Imported libraries
 stringr




## plot_sponsor_trend.R

Plot Sponsor Trend

The `plot_sponsor_trend()` function analyses and visualizes
the annual publication trends for sponsors
from Scopus search results.

### Parameter
 res Scopus search results, including `entries`, which is a list of publication details.
Each entry should have the fields `dc:title`, `prism:coverDate`, and `fund-sponsor` (with `fund-acr` for abbreviation).
### Returned value
 A ggplot2 object showing the trend analysis results over the years for each sponsor.
### Example usage of the function with the sample data
```r

# Create a sample `res` list to simulate Scopus API search results
res = list(
entries = list(
list(
`dc:title` = "A Study on Data Analysis",
`prism:coverDate` = "2022-12-31",
`fund-sponsor` = "National Science Foundation",
`fund-acr` = "NSF"
),
list(
`dc:title` = "Advances in Machine Learning",
`prism:coverDate` = "2021-11-30",
`fund-sponsor` = "China Scholarship Council",
`fund-acr` = "CSC"
),
list(
`dc:title` = "Research in Quantum Computing",
`prism:coverDate` = "2020-10-15",
`fund-sponsor` = "German Research Foundation",
`fund-acr` = "DFG"
),
list(
`dc:title` = "Innovations in AI",
`prism:coverDate` = "2019-09-01",
`fund-sponsor` = "Engineering and Physical Sciences Research Council",
`fund-acr` = "EPSRC"
),
list(
`dc:title` = "Exploring New Frontiers in Science",
`prism:coverDate` = "2018-08-01",
`fund-sponsor` = NULL,
`fund-acr` = NULL
)
)
)

# Example usage of the function with the sample data
plot_sponsor_trend( res )

```
### Imported libraries
 ggplot2
```
### Imported libraries
 dplyr
```
### Imported libraries
 tidyr
```
### Imported libraries
 ggrepel



## rank_affiliations.R

Generate a ranking of the top affiliation used in the provided Scopus search results.

The `rank_affiliations()` function generates a ranking of the top affiliations
from the provided Scopus search results,
based on the number of publications and total citations.
By choosing the `type = "city"` or `type = "institution"` option,
the function can provide the ranking of cities or institutions instead of countries.
The output is a tibble with the following columns:
`rank` rank of the affiliation,
`country/city/institution` type of the affiliation, and
`n` number of publications.

### Parameter
 res A list containing Scopus search results, including entries with `affiliation`.
### Parameter
 n An integer specifying the number of top keywords to return. Defaults to 20.
### Parameter
 type A character indicating what to rank. The value should be `country`, `city`, or `institution`. Default is `country`.

### Returned value
 A tibble with columns
`rank` (integer, rank),
`institution/country/city` (character), and
`n` (integer, occurrence count).

### Example usage of the function with the sample data
```r

# Load a sample Scopus search result object (res)
# Note: This is a placeholder example. In practice, you would load or obtain a real 'res' object.
res <- list(
entries = list(
list(
affiliation = list(
list(
`affiliation-country` = c("USA", "Canada", "Germany"),
`affiliation-city` = c("New York", "Toronto", "Berlin"),
`affilname` = c("Johns Hopkins University")
)
)
),
list(
affiliation = list(
list(
`affiliation-country` = c("USA", "France", "Germany"),
`affiliation-city` = c("San Francisco", "Paris", "Berlin"),
`affilname` = c("University of California")
)
)
)
)
)

# Generate a ranking of the top 20 countries
rank_affiliations( res )

# Generate a ranking of the top 20 cities
rank_affiliations( res, n = 20, type = "city")

```
### Imported libraries
 tibble
```
### Imported libraries
 dplyr
```
### Imported libraries
 utils




## rank_authors.R

Rank Authors by Number of Publications and Citations

The `rank_authors()` function generates a ranking of the top authors
from the provided Scopus search results,
based on the number of publications and total citations.
By setting the `include_all = TRUE` option, the function can include
not only the first authors but also all authors of the publications in the ranking.
The output is a tibble with the following columns:
`rank` rank of the author,
`name` author's name,
`n_publications` number of publications,
`n_citations` total number of citations,
`institution` author's primary institution, and
`country` author's country.

### Parameter
 res A list containing Scopus search results.
### Parameter
 n An integer specifying the number of top authors to return. Defaults to 20.
### Parameter
 include_all A logical value indicating whether to include secondary authors. Defaults to FALSE.

### Returned value
 A tibble with the ranking of authors.
### Example usage of the function with the sample data
```r

res <- list(
entries = list(
list(author = list(
list(authid = "012345", authname = "Smith J.",
affiliation = list(list(`affilname` = "University A",
`affiliation-country` = "Country A"))),
list(authid = "333333", authname = "Doe J.",
affiliation = list(list(`affilname` = "University B",
`affiliation-country` = "Country B")))),
`citedby-count` = 10, `prism:coverDate` = "2024-12-01"),
list(author = list(
list(authid = "012345", authname = "Smith J.",
affiliation = list(list(`affilname` = "University A",
`affiliation-country` = "Country A"))),
list(authid = "987654", authname = "Brown S.",
affiliation = list(list(`affilname` = "University C",
`affiliation-country` = "Country C")))),
`citedby-count` = 5, `prism:coverDate` = "2020-12-01")
)
)
rank_authors(res, n = 20, include_all = FALSE)

```
### Imported libraries
 utils




## rank_keywords.R

Generate a ranking of the top keywords used in the provided Scopus search results.

The `rank_keywords()` function generates a ranking of the top keywords
from the provided Scopus search results,
based on the number of publications and total citations.
By setting the `abst = TRUE` option, the function can include
not only the keywords tagged by the authors
but also the abstracts of the papers in the ranking.
The output is a tibble with the following columns:
`rank` rank of the keyword,
`keyword` the keyword, and
`n` number of publications with the keyword.

### Parameter
 res A list containing Scopus search results, including entries with `authkeywords` and `dc:description`.
### Parameter
 n An integer specifying the number of top keywords to return. Defaults to 20.
### Parameter
 abst A logical value indicating whether to include keywords from the abstracts. Default is `FALSE`.
### Returned value
 A tibble with columns
`rank` (integer, rank),
`keyword` (character, keyword), and
`n` (integer, occurrence count).
### Example usage of the function with the sample data
```r

res <- list(
entries = list(
list( authkeywords = "machine learning | AI | deep learning",
`dc:description` = "This is an abstract about AI." ),
list( authkeywords = "machine learning | data mining",
`dc:description` = "Abstract about data mining and machine learning." )
)
)

rank_keywords( res, abst = TRUE )

```
### Imported libraries
 dplyr
```
### Imported libraries
 utils
```
### Imported libraries
 litsearchr




## rank_sponsors.R

Rank Sponsors by Number of Publications and Citations

The `rank_sponsors()` function generates a ranking of the top sponsors
from the provided Scopus search results,
based on the number of publications and total citations.
The output is a tibble with the following columns:
`rank` rank of the sponsor,
`sponsor` sponsor's name with abbreviation,
`n_publications` number of publications,
`n_citations` total number of citations,
`cite_per_pub` average number of citations per publication,
`countries_display` comma-separated list of countries where the sponsor is active, and
`countries` list of countries where the sponsor is active.

### Parameter
 res A list containing Scopus search results.
### Parameter
 n An integer specifying the number of top sponsors to return. Defaults to 20.

### Returned value
 A tibble with the ranking of sponsors.
### Example usage of the function with the sample data
```r

res <- list(
entries = list(
list(`fund-sponsor` = "Youth Innovation Promotion Association",
`fund-acr` = "YIPA",
affiliation = list(list(`affiliation-country` = c("Country A", "Country B"))),
`citedby-count` = 10),
list(`fund-sponsor` = "National Science Foundation",
`fund-acr` = "NSF",
affiliation = list(list(`affiliation-country` = c("Country C"))),
`citedby-count` = 5)
)
)
rank_sponsors(res, n = 20)

```
### Imported libraries
 utils




## sna_countries.R

Social Network Analysis - Network of Country Co-occurrences

The `sna_countries()` function analyses co-occurrence data between countries based on shared keywords
and creates a network graph visualizing the relationships between countries.
The network is constructed based on the frequency of shared keywords between countries.
The resulting graph can help in understanding how countries are connected through common research topics.

### Parameter
 res A list containing Scopus search results, which includes:
- `entries`: A list of publication entries where each entry contains:
- `authkeywords`: Keywords related to the publication, separated by `|`.
- `affiliation`: A list of affiliation details, including:
- `affiliation-country`: The country associated with the publication's affiliation.

### Returned value
 A `ggraph` object showing the network of countries based on their co-occurrence in research topics.
The network visualizes countries as nodes and the strength of their connections (based on shared keywords)
as edges between these nodes. Nodes are sized according to their importance in the network, and edges
are colored based on their weight.

### Example usage of the function with the sample data
```r

res <- list(
entries = list(
list(
authkeywords = "Artificial Intelligence|Machine Learning",
affiliation = list(
list( `affiliation-country` = "USA" )
)
),
list(
authkeywords = "Artificial Intelligence|Data Science",
affiliation = list(
list( `affiliation-country` = "UK" )
)
),
list(
authkeywords = "Machine Learning|Data Science",
affiliation = list(
list( `affiliation-country` = "Canada")
)
),
list(
authkeywords = "Artificial Intelligence|Machine Learning|Data Science",
affiliation = list(
list( `affiliation-country` = "Germany")
)
)
)
)

network_graph <- sna_countries( res )
print( network_graph )

```
### Imported libraries
 dplyr




## sna_topic_country.R

Social Network Analysis - Topic-Country Relationship

The `sna_topic_country()` function analyses a network analysis based on topics (keywords) and countries
from the given publication data. It visualizes the relationship between different
topics and the countries associated with those topics.

### Parameter
 res A list containing Scopus search results with an `entries` element,
where each entry contains `authkeywords` (keywords separated by '|'),
`dc:description` (abstract), and `affiliation` (containing `affiliation-country`).

### Returned value
 A `ggraph` object that visualizes the network of topics and countries.
The plot includes nodes representing topics and countries, with edges showing
the connections between them. Nodes are color-coded by their type (topics or countries),
and edge thickness is proportional to the number of shared keywords between topics and countries.
The color of the edges is determined by the frequency of connections, with a gradient
from light blue (low frequency) to dark blue (high frequency).

### Example usage of the function with the sample data
```r

res <- list(
entries = list(
list(
authkeywords = "AI|Machine Learning|Data Science",
dc.description = "This paper discusses advancements in AI and machine learning.",
affiliation = list(
list(`affiliation-country` = "United States"),
list(`affiliation-country` = "China")
)
),
list(
authkeywords = "Quantum Computing|AI",
dc.description = "Explores quantum computing and its applications in AI.",
affiliation = list(
list(`affiliation-country` = "Germany")
)
)
)
)

sna_topic_country( res )

```
### Imported libraries
 dplyr
```
### Imported libraries
 utils
```
### Imported libraries
 ggplot2




## zzz.R

No description available.

