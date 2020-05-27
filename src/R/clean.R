clean_empty_columns <- function (input_filename, output_filename){
  df <- read_delim(input_filename, delim='|')
  df <- select(df, -starts_with('X'))
  write_delim(df, output_filename, delim='|')
}