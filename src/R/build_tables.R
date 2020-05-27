all_tables = c('per_game', 'highs', 'pbp', 'per_36', 'shooting', 'totals',
               'advanced', 'per_poss', 'playoff_advanced', 'playoff_highs', 'playoff_pbp', 'playoff_per_36', 
               'playoff_per_game', 'playoff_per_poss', 'playoff_shooting')
df_by_season <- player_stats_by_season(all_tables)

df_career <- player_stats_career(df_by_season)
