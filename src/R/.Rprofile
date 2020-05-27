library(stats)
library(tidyverse)
library(lubridate)

data_path <- '../../data'
processed_data_path <- str_c(data_path, '/processed2')
raw_data_path <- str_c(data_path, '/raw2')

players <- read_delim(paste(data_path, 'processed2', 'player_list', sep='/'), '|', col_types = 'cciiciiiiDc') %>% arrange(player_id)
all_player_ids <- players$player_id

source('~/Coding/nba2/src/R/utility.R')
