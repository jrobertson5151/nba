career_totals_player <- function(player_id_str) {
  loc <- paste(data_path, 'player', player_id_str, 'totals', sep='/')
  if(file.exists(loc)) {
    df <- read_delim(loc, '|', col_types = cols())
    df <- df %>%
      summarise_if(is.numeric, list(sum)) %>%
      select(-contains('%'), -starts_with('X1'), -starts_with('Age'))
    df$player_id = player_id_str
    df <- select(df, player_id, everything())
    return(df)
  }
}

career_totals <- function(pl=all_player_ids) {
  df <- NULL
  for (pi in pl){
    df <- bind_rows(df, career_totals_player(pi))
  }
  df <- right_join(players, df, by='player_id') %>%
    rename(College = Colleges) %>%
    mutate(`3P%` = `3P`/`3PA`, `FT%` = FT/FTA, `2P%` = `2P`/`2PA`, `FG%` = FG/FGA) %>%
    mutate(MP = MP/G, FG = FG/G, FGA = FGA/G, `3P` = `3P`/G, `3PA` = `3PA`/G, 
           `2P` = `2P`/G, `2PA` = `2PA`/G, FT = FT/G, FTA = FTA/G, ORB = ORB/G, DRB = DRB/G, TRB = TRB/G, AST = AST/G, 
           STL = STL/G, BLK = BLK/G, TOV = TOV/G, PF = PF/G, PTS = PTS/G) %>%
    select(player_id:MP, starts_with('FG'), starts_with('2P'), starts_with('3P'), starts_with('FT'), everything())
  return(df)
}