library(gganimate)

player_dist <- left_join(per_game_season, advanced_season) %>% only_totals %>%
  mutate(decade = as.factor(as.integer(10*as.integer(substring(Season, 1, 3))))) %>%
  select(player_id, Season, decade, everything())

anim <- ggplot(player_dist, aes(x=PTS)) + geom_density() + 
  ggtitle('Season {closest_state}') + 
  transition_states(Season, transition_length = 2, state_length=1)