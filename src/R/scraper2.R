library(tidyverse)
library(RSelenium)
library(rvest)
library(xml2)

#run in terminal: 'sudo docker run -d -p 4445:4444 selenium/standalone-firefox'

# remDr <- remoteDriver(port=4445L)
# remDr$open()

bball_url <- 'https://www.basketball-reference.com'
raw_path <- '../../data/raw'
 
save_all_tables <- function(dest, html_str) {
  ids <- html_str %>% html_nodes('table') %>% html_attr('id')
  tables <- html_str %>% html_table() %>% .[!is.na(ids)]
  ids <- ids[!is.na(ids)]
  map(1:length(ids), ~write_csv(tables[[.]], str_c(dest, '/', ids[[.]], '.csv')))
}

wait_until_loaded <- function(url) {
  remDr$navigate(url)
  i <- 0
  while(try(!str_detect(remDr$getCurrentUrl()[[1]], url))){
    print(i)
    print(url)
    print(remDr$getCurrentUrl()[[1]])
    Sys.sleep(1)
    i <- i+1
  }
}

write_letters_html <- function(dest=str_c(raw_path, '/letters')) {
  if(!dir.exists(dest))
    dir.create(dest)
  for(c in letters){
    letter_dest = str_c(dest, '/', c, '.html')
    if(file.exists(letter_dest)){
      print(str_c('Letter', c, 'already exists'))
      next()
    }
    url <- str_c(bball_url, '/players/', c)
    wait_until_loaded(url)
    html_str <- remDr$getPageSource()[[1]]
    print(str_c('writing ', c))
    output_file <- file(letter_dest)
    writeLines(html_str, output_file)
    close(output_file)
  }
}

save_player_html <- function(player_id, location) {
  print(player_id)
  dest_loc <- str_c(location, '/', player_id, '.html')
  if(file.exists(dest_loc)){
    print(str_c(dest_loc, ' already exists'))
    return()
  }
  html_loc <- paste(bball_url, 'players', substr(player_id, 1, 1), str_c(player_id, '.html'), sep='/')
  wait_until_loaded(html_loc)
  html_str <- remDr$getPageSource()[[1]]
  output_file <- file(dest_loc)
  writeLines(html_str, output_file)
  close(output_file)
  return()
} 

save_all_players <- function(location = NULL, player_list=NULL){
  if(is.null(player_list))
    player_list <- read_delim(str_c(processed_data_path, '/player_list'), delim='|')$player_id
  if(is.null(location))
    location <- raw_data_path
  for(pi in player_list){
    save_player_html(pi, location)
  }
}

file_is_good <- function(location, player_id){
  html_loc <- str_c(location, '/', player_id, '.html')
  if(!file.exists(html_loc)){
    return(FALSE)
  }
  pi_table <- read_html(html_loc) %>%
    html_nodes('table#totals')
  if(length(pi_table) == 0){
    print(str_c(player_id, ' is bad'))
    return(FALSE)
  }
  print(str_c(player_id, ' is good'))
  return(TRUE)
}

name_unnamed_cols <- function(df){
  unnamed_col_vec <- names(df) == ''
  names(df)[unnamed_col_vec] <- map_chr(1:sum(unnamed_col_vec), ~ str_c('col', as.character(.), sep='_'))
  return(df)
}

game_data <- function(player_ids=NULL, seasons=NULL) {
  game_data_by_player <- function(player_id, season){
    print(str_c('getting game data for ', player_id, ' in season ', seasons))
    url <- str_c(bball_url, '/players/', substr(player_id, 1, 1), '/', player_id, '/gamelog/', season+1)
    remDr$navigate(url)
    Sys.sleep(1)
    i <- 0
    while(try(remDr$getCurrentUrl()[[1]] != url)){
      print(i)
      print(url)
      print(remDr$getCurrentUrl()[[1]])
      Sys.sleep(1)
      i <- i+1
    }
    df <- remDr$getPageSource()[[1]] %>% read_html() %>% html_node('table#pgl_basic') 
    df <- html_table(df) 
    df <- tibble(name_unnamed_cols(df)) %>% filter(G != '' & G != 'G')
    secs_played <- as.integer(map_dbl(str_split(df$MP, ':'), ~ 60*as.integer(.[[1]])+as.integer(.[[2]])))
    df <- type_convert(df, col_types=cols(GmSc=col_double(), Date=col_date(format='%Y-%m-%d'), MP=col_character())) %>%
            mutate(secs_played = secs_played, 
              Home = (is.na(col_1) | col_1 != '@'),
              Win = (str_detect(col_2, 'W')),
              started = (GS == 1),
              game_num = Rk,
              season=season,
              player_id=player_id
            ) %>%
            select(-contains('%'), -contains('+/-'), -MP, -Age, -contains('col_'), -Rk, -GS) %>%
            select(player_id, season, everything()) %>%
            mutate_at(vars(FG:PTS), as.integer)
    Sys.sleep(1)
    return(df)
  }
  game_data_by_season <- function(player_ids=NULL, season){
    if(is.null(player_ids))
      return(bind_rows(map(players_in_season(season), ~ game_data_by_player(., season))))
    else
      return(bind_rows(map(intersect(players_in_season(season), player_ids), ~game_data_by_player(., season))))
  }
  if(!is.null(seasons))
    return(bind_rows(map(seasons, ~game_data_by_season(player_ids, .))))
  else
    return(bind_rows(map(1960:2019, ~game_data_by_season(player_ids, .))))
}

players_in_season <- function(season){
  filter(per_game_season, Season == season)$player_id %>% unique()
}

build_box_scores <- function(seasons){
  for(s in seasons) {
    write_delim(game_data(seasons = s), str_c(processed_data_path, '/box_scores/', s), delim='|')
  }
}