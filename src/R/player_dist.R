library(gganimate)
library(gifski)
library(png)
library(transformr)

player_dist <- left_join(per_game_season, advanced_season) %>% only_totals %>%
  mutate(decade = as.factor(as.integer(10*as.integer(substring(Season, 1, 3))))) %>%
  select(player_id, Season, decade, everything())

anim <- player_dist %>% filter(!is.na(MP)) %>%
  ggplot(aes(x=MP)) + geom_density() + 
  ggtitle('Season {closest_state}') + 
  transition_states(Season, transition_length = 1, state_length=2)

# three_point_rate_by_pos <- player_dist %>% filter(!is.na(`3PAr`)) %>% simplify_position() %>%
#   group_by(Season, Pos) %>% summarise(avg_3PAr = weighted.mean(`3PAr`, MP*G)) %>% 
#   ggplot(aes(x=Season, y=avg_3PAr, color=Pos)) + geom_line()
# 

points_by_pos <- totals_season %>% left_join(select(per_game_season, player_id:Pos)) %>% 
  only_totals() %>% simplify_position() %>% group_by(Season, Pos) %>%
  summarise(PTS=sum(PTS)) %>% 
  ggplot(aes(x=Season, y=PTS, fill=Pos)) +
  geom_bar(position = 'fill', stat='identity')

heights_over_time <- players %>%
  add_height_in_inches %>%
  select(player_id, Height_in_inches) %>%
  left_join(only_totals(simplify_position(per_game_season)), .) %>%
  select(player_id, Player, Season, Pos, G, GS, MP, Height_in_inches) %>%
  group_by(Season, Pos) %>% summarise(avg_ht = weighted.mean(Height_in_inches, MP*G)) %>%
  filter(!is.na(Pos) & !is.na(avg_ht)) %>%
  ggplot(aes(x=Season, y=avg_ht, color = Pos)) + 
  geom_line()

heights_by_draft_year <- players %>% add_height_in_inches() %>% filter(!is.na(Height)) %>%
  right_join(totals_career) %>% 
  group_by(From, Pos) %>% 
  summarise(avg_ht = weighted.mean(Height_in_inches, MP)) %>%
  ggplot(aes(x=From, y=avg_ht, color=Pos)) +
  geom_line()

three_point_rate_by_pos <- totals_season %>% only_totals %>% filter(Season > 1978) %>% 
  left_join(select(per_game_season, player_id, Pos)) %>% 
  simplify_position() %>% 
  group_by(Season, Pos) %>% 
  summarise(FGA=sum(FGA), `3PA`=sum(`3PA`)) %>% 
  ggplot(aes(x=Season, y=`3PA`/FGA, color=Pos)) + geom_line()
  
position_bluriness <- pbp_season %>% 
  left_join(select(totals_season, player_id, Season, MP), by=c('player_id', 'Season')) %>% 
  only_totals() %>% rowwise() %>% 
  mutate(other_pos_perc = 1-max(c_across(ends_with('%'))), pos=which.max(c_across(ends_with('%')))) %>% 
  group_by(Season, pos) %>% 
  summarise(other_pos_perc = weighted.mean(other_pos_perc, MP)) %>% 
  ggplot(aes(x=Season, y=other_pos_perc, color=as.factor(pos))) +
  geom_line()
