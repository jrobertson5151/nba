# rolling_sum <- function(xs){
#   ys = rep(0, length(xs))
#   for(i in seq_along(xs)){
#     ys[i] = sum(xs[1:i])
#   }
#   return(c(NA, ys[1:length(xs)-1]))
# }
# 
# shift1 <- function(xs){
#   c(NA, xs[1:length(xs)-1])
# }

df <- only_totals(totals_season) %>% select(player_id,Season, `3P`:`3P%`) %>% group_by(player_id) %>%
  mutate_at(vars(starts_with('3P')), list(to_date=rolling_sum)) %>% mutate(`3P%_to_date`=`3P_to_date`/`3PA_to_date`) %>%
  mutate(last_season_perc = shift1(`3P%`)) %>% mutate(season_num = rank(Season), seasons_played=n()) %>%
  mutate(`3P_per_season`=`3P_to_date`/(season_num-1), `3PA_per_season`=`3PA_to_date`/(season_num-1)) %>%
  filter(`3PA_to_date` > 100)

#lm_3P <- lm(`3P` ~ `3P_per_season`, df)
#lm_3PA <- lm(`3PA` ~ `3PA_per_season`, df)

threes_by_group <- function(seasons, ...) {
  df <- box_scores(seasons) %>% select(player_id, season, G, Date,Tm, Opp,`3P`, `3PA`, Home:game_num)
  expr <- enquos(...)
  df <- df %>% group_by(!!! expr) %>%
    summarise(total_3PA = sum(`3PA`), total_3P = sum(`3P`)) %>%
    mutate(`3P%`= total_3P/total_3PA) %>%
    ungroup()
  return(df)
}

df2 <- box_scores(2000:2010) %>% left_join(players) %>% 
  select(Player, season, player_id, G, Date, starts_with('3P'), From, To) %>% 
  filter(From > 1999) %>%
  group_by(player_id) %>%
  mutate(G = 1:n(), cum_3P = cumsum(`3P`), cum_3PA = cumsum(`3PA`)) %>%
  mutate(total_G = max(G), total_3P = max(cum_3P), total_3PA = max(cum_3PA), total_3P_perc = total_3P/total_3PA) %>%
  select(-From, -To)  


