path_to_table <- function(name_of_table) {
  str_c(processed_data_path, '/', name_of_table, '.csv')
}

only_totals <- function(tb){
  grouped_df <- tb %>% group_by(player_id, Season) %>% mutate(n=n())
  return(bind_rows(filter(grouped_df, n == 1), filter(grouped_df, n > 1 & Tm == 'TOT')) %>% 
           select(-n) %>% arrange(player_id, Season) %>% ungroup())
}

names_of_all_tables <- c('per_game_season', 'per_minute_season', 'advanced_season', 'pbp_season', 'totals_season',
                         'per_game_career', 'per_minute_career', 'advanced_career', 'pbp_career', 'totals_career')
map(names_of_all_tables, ~ (assign(., read_csv(path_to_table(.), col_types = cols()), envir=.GlobalEnv)))

#add parsing specs

box_scores <- function(seasons){
  bind_rows(map(seasons, ~read_delim(str_c(processed_data_path, '/box_scores/', .), delim='|', 
                                     col_types = 'ciiDcciiiiiiiiiiiiiiidillli')))
}
