player_names <- select(players, player_id, Player)

path_to_table <- function(name_of_table) {
  str_c(processed_data_path, '/', name_of_table, '.csv')
}

only_totals <- function(tb){
  if(!('Season' %in% names(tb)))
    return(tb)
  grouped_df <- tb %>% group_by(player_id, Season) %>% mutate(n=n())
  return(bind_rows(filter(grouped_df, n == 1), filter(grouped_df, n > 1 & Tm == 'TOT')) %>% 
           select(-n) %>% arrange(player_id, Season) %>% ungroup())
}

add_height_in_inches <- function(df) {
  str_split(df$Height, '-') %>% 
    map_dbl(~12*as.numeric(.[[1]])+as.numeric(.[[2]])) %>% 
    as.integer() %>%
    mutate(df, Height_in_inches = .)
}

spec_df <- read_csv('spec_strings.csv', col_types = 'cc')
names_of_all_tables <- spec_df$table_names
spec_strings <- spec_df$spec_strings
names(spec_strings) <- names_of_all_tables

read_table <- function(table_name) {
  df <- right_join(player_names, 
                   read_csv(path_to_table(table_name), col_types = spec_strings[[table_name]]), 
                   by=c('player_id'))
  if(str_detect(table_name, 'season')) {
    df <- mutate(df, Season = as.integer(substring(Season, 1, 4)))
  }
  return(df)
}

map(names_of_all_tables, ~ (assign(., only_totals(read_table(.)), envir = .GlobalEnv)))

fix_pbp <- function(df){
  df %>% mutate_at(vars(ends_with('%')), ~if_else(is.na(.), 0,
                                                  .01*as.numeric(str_remove(., '%'))) )
}

pbp_season <- fix_pbp(pbp_season)
pbp_career <- fix_pbp(pbp_career)
playoffs_pbp_season <- fix_pbp(playoffs_pbp_season)
playoffs_pbp_career <- fix_pbp(playoffs_pbp_career)

box_scores <- function(seasons){
  bind_rows(map(seasons, ~read_delim(str_c(processed_data_path, '/box_scores/', .), delim='|', 
                                     col_types = 'ciiDcciiiiiiiiiiiiiiidillli')))
}

suppressWarnings(remove(spec_df, player_names, data_path, spec_strings, read_table, path_to_table))

players <- filter(players, player_id %in% per_game_career$player_id)

simplify_position <- function(df) {
  helper <- function(p){
    if(p %in% c('PG', 'SG', 'FG', 'PF', 'C') || is.na(p))
      return(p)
    if(substring(p, 1, 1) %in% c('C', 'F', 'G'))
      return(substring(p,1,1))
    else
      return(substring(p,1,2))
  }
  mutate(df, Pos = map_chr(Pos, helper))
}
