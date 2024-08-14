library(stringr)

pull_text <- function( filename ) {
  filepath = paste0("R/", filename )
  txt <- readLines( filepath )
  txt <- gsub("^#'\\s*", "", txt )
  sec <- unlist( strsplit( paste( txt, collapse = "\n"), "\n\n" ) )
  return( sec[2] )
}

desc_lines <- readLines( "DESCRIPTION" )

package_name <- str_extract( desc_lines[1], "(?<=Package: )[^\\s]+" )

description <- str_extract( paste( desc_lines, collapse = " " ), "(?<=Description: ).*?(?= License:)" )
license <- str_extract( paste( desc_lines, collapse = " " ), "(?<=License: )[^\\s]+" )
encoding <- str_extract( paste( desc_lines, collapse = " " ), "(?<=Encoding: )[^\\s]+" )
roxygen_note <- str_extract( paste(desc_lines, collapse = " " ), "(?<=RoxygenNote: )[^\\s]+" )
imports <- str_extract(paste( desc_lines, collapse = " " ), "(?<=Imports: ).*" )
imports_list <- strsplit( imports, ",\\s*" )[[1]]

description_section <- paste(
  description, "\n\n",
  "- **License**: ", license, "\n",
  "- **Encoding**: ", encoding, "\n",
  "- **RoxygenNote**: ", roxygen_note, "\n",
  "- **Imports**:", paste( imports_list, collapse = ", "), sep = ""
)

r_files <- list.files( path = "R", pattern = "\\.R$", full.names = FALSE )

r_descriptions <- lapply( r_files, function( file ) {
  if ( file == "zzz.R" ){ text <- "| | |" }
  else {
    title <- gsub( "_", " ", sub( "\\.R$", "", file ) )
    title <- tools::toTitleCase( title )
    expls <- gsub( "\n", " ", pull_text( file ) )
    text <- paste0( "| ", title, " | ", expls, " |" )
  }
})

manual_content <- paste(
  "# ", package_name, "\n\n",
  description_section, "\n\n",
  "### **Functions**\n",
  "| Name | Overview | \n",
  "| --- | --- | \n",
  paste( r_descriptions, collapse = "\n" ),
  sep = ""
)

writeLines( manual_content, "README.md" )

print( "README.md has been generated successfully." )
