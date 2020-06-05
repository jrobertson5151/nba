source('./parser.R')
source('./scraper2.R')

#run in terminal: 'sudo docker run -d -p 4445:4444 selenium/standalone-firefox'

# remDr <- remoteDriver(port=4445L)
# remDr$open()
player_table_names <- c('')

if(!dir.exists(raw_data_path))
  dir.create(raw_data_path)
if(!dir.exists(processed_data_path))
  dir.create(processed_data_path)

player_file_path <- str_c(processed_data_path)
if(!file.exists(player_file_path)){
  print('player_list doesn\'t exist')
  write_letters_html()
  write_player_list()
}

players <- read_delim(paste(data_path, 'processed', 'player_list', sep='/'), '|', col_types = 'cciicciDc') %>% 
  arrange(player_id)

print('loaded player_list')

#scrape for player data
players_data_path <- str_c(raw_data_path, '/players/') 
for(pi in players$player_id){
  pi_data_path <- str_c(players_data_path, pi)
  if(!dir.exists(pi_data_path)) {
    print(str_c(pi_data_path, ' does not exist'))
    html_file_loc <- str_c(raw_data_path, '/', pi, '.html')
    if(file.exists(html_file_loc)){
      html_str <- read_html(html_file_loc)
      print(str_c('already have data for ', pi))
    } 
    else {
      url <- str_c(bball_url, '/players/', substr(pi, 1, 1), '/', pi, '.html')
      wait_until_loaded(url)
      html_str <- remDr$getPageSource()[[1]] %>% read_html()
      print(str_c('fetched data for ', pi))
    }
    dir.create(pi_data_path, recursive =  TRUE)
    save_all_tables(pi_data_path, html_str)
    print(str_c('saved tables for ', pi))
  }
  else {
    print(str_c(pi_data_path, ' already exists'))
  }
}

#parse player data
players_filenames <- dir(players_data_path, recursive = TRUE)
for(t in table_names){
  t_season_filename <- str_c(processed_data_path, '/', t, '_season.csv')
  t_career_filename <- str_c(processed_data_path, '/', t, '_career.csv')
  if(file.exists(season_filename) && file.exists(t_career_filename)){
    print(str_c(t, ' already exists'))
    next()
  }
  t_files <- players_filenames[str_detect(players_filenames, str_c('/', t, '.csv'))] %>%
    str_c(players_data_path, .)
  players_with_t <-  t_files %>%
    str_split('/') %>%
    map_chr(~.[[6]])
  big_df <- bind_rows(map(1:length(t_files), 
                          ~read_csv(t_files[.]) %>% 
                            mutate(player_id = players_with_t[.])))
  
}

