library(stats)
library(tidyverse)
library(lubridate)
library(ggplot2)

data_path <- '../../data'
processed_data_path <- str_c(data_path, '/processed')
raw_data_path <- str_c(data_path, '/raw')

players <- read_delim(paste(data_path, 'processed', 'player_list', sep='/'), '|', col_types = 'cciicciDc') %>% arrange(player_id)
all_player_ids <- players$player_id
source('~/Coding/nba2/src/R/utility.R')
