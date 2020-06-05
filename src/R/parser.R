shooting_cols <- c('Season', 'Age', 'Tm', 'Lg','Pos','G','MP','FG%','avg_distance','percent_from_2P', 'percent_from_0-3', 
                   'percent_from_3-10','percent_from_10-16', 'percent_from_16-3P', 'percent_from_3P', 'percent_made_2P', 
                   'percent_made_0-3','percent_made_3-10', 'percent_made_10-16', 'percent_made_16-3P', 'percent_made_3P', 
                   'assisted_2P', 'percent_from_dunks', 'made_dunks', 'assisted_corner_3P', 'percent_from_corner_3P', 
                   'percent_made_corner_3P', 'heaves_attempted', 'heaves_made')
pbp_cols <- c("Season", "Age", "Tm", "Lg", "Pos", "G", "MP", "PG%", "SG%", 
              "SF%", "PF%", "C%", "OnCourt", "On-Off", "BadPass", "LostBall", 
              "shooting_fouls_committed", "offensive_fouls_committed", "shooting_fouls_drawn", 
              "offensive_fouls_drawn", "points_generated_by_assists", "and_ones", "blocked_shots")
highs_cols <- c("Season", "Age", "Tm", "Lg", "MP", "FG", "FGA", "3P", "3PA", 
                "2P", "2PA", "FT", "FTA", "ORB", "DRB", "TRB", "AST", "STL", 
                "BLK", "TOV", "PF", "PTS", "GmSc")

tbls <- c('per_game', 'totals', 'highs', 'per_minute', 'per_poss', 'advanced', 'shooting', 'playoffs_per_game', 
          'playoffs_shooting', 'playoffs_totals', 'playoffs_highs', 'playoffs_per_minute', 'playoffs_per_poss', 
          'playoffs_advanced')

library(tidyverse)
library(rvest)
library(lubridate)

write_player_list <- function(input = raw_data_path, dest=str_c(processed_data_path, '/player_list')){
  pids <-  c()
  df_by_letter <- function(c){
    html_path  <- str_c(input, '/letters/', c, '.html')
    html_str <- read_html(html_path)
    df_letter <-  html_str %>%
      html_node('table#players') %>%
      html_table() %>% 
      tibble() %>%
      mutate_if(is.numeric, as.character)
    letter_pids <- html_str %>%
      html_nodes('th[data-append-csv]') %>% html_attr('data-append-csv')
    pids <<- c(pids, letter_pids)
    return(df_letter)
  }
  df <- bind_rows(map(letters, df_by_letter)) %>%
    filter(From != 'From') %>%
    mutate(`Birth Date` = parse_date(`Birth Date`, '%B %d, %Y')) %>%
    type_convert(col_types = 'ciicciDc') %>%
    mutate(Player = str_remove(Player, '\\*')) %>% 
    rename(Birth_date = `Birth Date`, Height = Ht, Weight = Wt) %>%
    mutate(player_id = pids) %>%
    select(player_id, everything())
  write_delim(df, dest, delim='|')
}

get_table <- function(location, player_ids, table_name){
  df <- NULL
  for(pi in player_ids){
    pi_nodes <- read_html(str_c(location, '/', pi, '.html')) %>%
      html_nodes(str_c('table#', table_name)) 
    if(length(pi_nodes) == 0){
      print(str_c('no ', table_name, ' for ', pi))
      pi_table <- data.frame(player_id = c(pi))
      }
    else {
      print(str_c('found ', table_name, ' for ', pi))
      pi_table <- pi_nodes[[1]] %>%
        html_table() 
      if(str_detect(table_name, 'shooting')){
        pi_table <- pi_table[3:nrow(pi_table),]
        names(pi_table) <- shooting_cols
      }
      if(str_detect(table_name, 'pbp')){
        pi_table <- pi_table[2:nrow(pi_table),]
        names(pi_table) <- pbp_cols
      }
      if(str_detect(table_name, 'highs')){
        names(pi_table) <- pi_table[1,] %>% as.character()
        pi_table <- pi_table[2:nrow(pi_table),]
        
      }
      pi_table <- pi_table %>%
        Filter(function(x)!all(is.na(x)), .)  %>%
        mutate(player_id = pi) %>%
        mutate_all(as.character)
      df <- pi_table %>% bind_rows(df, .)
    }
  }
  df <- df  %>% select(player_id, everything()) %>% 
    as_tibble()
  if(str_detect(table_name, 'highs'))
    df <- filter(df, FG != '') %>% filter(Lg == 'NBA' | Lg == '') %>% select(-Lg)
  else if('Lg' %in% names(df)){
    df <- filter(df, Lg == 'NBA' | Lg == '') %>% select(-Lg)
  }
  return(df)
}

save_table <- function(write_location, read_location, table_name, player_ids = all_player_ids, raw_data = NULL){
  if (is.null(raw_data)){ 
    if(table_name == 'highs'){
      df <- get_table(read_location, player_ids, 'year-and-career-highs')
    }
    else if(table_name == 'playoffs_highs'){
      df <- get_table(read_location, player_ids, 'year-and-career-highs-po')
    }
    else {
    df <- get_table(read_location, player_ids, table_name)
    }
  }
  else {
    df <- raw_data
  }
  if(!(str_detect(table_name,'(per_game)|(totals)|(highs)'))){
    df <- select(df, -any_of('MP'))
  }
  if(!(table_name %in% c('per_game', 'playoffs_per_game'))){
    df <- select(df, -any_of(c('G', 'GS')))
  }
  if(table_name != 'per_game'){
    df <- select(df, -any_of(c('Age', 'Pos', 'Lg')))
  }
  df_career <- df %>% filter(Season == 'Career' | Season == '') %>% select(-any_of(c('Season', 'Tm', 'Age', 'Pos')))
  write_csv(df_career, str_c(write_location, '/', table_name, '_career.csv'))
  df_season <- df %>% filter(str_detect(Season, '-')) %>% filter_all(all_vars(is.na(.) | !str_detect(., 'Did')))
  write_csv(df_season, str_c(write_location, '/', table_name, '_season.csv')) 
}

build <- function(){
  for(t in tbls){
    if(!file.exists(str_c(processed_data_path, '/', t, '.csv')))
      save_table(processed_data_path, raw_data_path, t, players$player_id)
  }
}

player_html <- function(player_id, location=raw_data_path){
  read_html(str_c(location, '/', player_id, '.html'))
}