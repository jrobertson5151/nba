adv_df <- advanced_season %>% 
  left_join(select(per_game_season, player_id, Season, Tm, Age), by=c('player_id', 'Season', 'Tm')) %>% 
  only_totals() %>% 
  mutate(next_id = lead(player_id), next_year = lead(Season), 
         in_league_next_year = (player_id == next_id) & (next_year == Season+1)) %>% 
  select(player_id:Tm, Age, in_league_next_year, PER:VORP) 

logitMod <- glm(in_league_next_year ~ WS + Age, data=filter(adv_df, Season < 2018), family=binomial(link='logit'))

preds <- plogis(predict(logitMod, filter(adv_df, Season == 2018))) %>% 
  as_tibble_col('prob') %>%
  bind_cols(filter(adv_df, Season == 2018))
