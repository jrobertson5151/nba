single_player_table <- function(player_id_str, table_name_str) {
  loc <- paste(data_path, 'player', player_id_str, table_name_str, sep='/')
  if(file.exists(loc)) {
    df <- read_delim(loc, delim='|', col_types = 
                       cols(Season=col_character(),
                            Tm = col_character(),
                            Lg = col_character()))
    df <- df %>%
      select(-contains('%'), -contains('Pos'), -starts_with('X1'), -starts_with('Age'))
    df$player_id = player_id_str
    df <- select(df, player_id, everything()) 
    if (!(table_name_str %in% c('highs', 'playoff_highs'))) {
    df <- filter(df, !str_detect(G, 'Did')) %>%
      as.data.frame() %>%
      type_convert(col_types=cols())
    }
    return(df)
  }
}

all_players_table <- function(table_name_str, pl=players$player_id) {
  df <- NULL
  for (pi in pl) {
    df <- bind_rows(df, single_player_table(pi, table_name_str))
  }
  return(df)
}

player_stats_by_season <- function(table_names = c('per_game', 'totals', 'advanced'), pl = players$player_id){
  df <- filter(players, player_id %in% pl) %>% nest(Bio=From:College)
  for (t in table_names){
    next_table = all_players_table(t, pl)  %>% 
      group_by(player_id) %>%
      nest() %>%
      rename(!!t := data)
    df <- full_join(df, next_table)
  }
  return(df)
}

player_stats_career <- function(by_season){
  career <- by_season %>% unnest(totals) %>% select(player_id, Player, G:PTS) %>%
    group_by(player_id, Player) %>% summarise_all(sum) %>% ungroup()
  career <- (select(career, MP:PTS)/career$G) %>% mutate(player_id = career$player_id) %>% 
    nest(per_game=MP:PTS) %>% full_join(career, .)
  career <- (select(career, FG:PTS)/career$MP*36) %>% mutate(player_id = career$player_id) %>% 
    nest(per_36=FG:PTS) %>% full_join(career, .)
  career <- career %>% nest(totals=G:PTS)
  return(career)
}