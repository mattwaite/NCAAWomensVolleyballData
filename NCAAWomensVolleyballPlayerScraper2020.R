library(tidyverse)
library(lubridate)
library(rvest)
library(janitor)

urls <- read_csv("url_csvs/ncaa_womens_volleyball_teamurls_2020.csv") %>% pull(2)

root_url <- "https://stats.ncaa.org"
season = "2020"

playerstatstibble <- tibble(
  team = character(),
  season = character(),
  jersey = character(),
  full_name = character(),
  roster_name = character(),
  last_name = character(),
  first_name = character(),
  yr = character(),
  pos = character(),
  feet = numeric(),
  inches = numeric(),
  gp = numeric(),
  gs = numeric(),
  mp = numeric(),
  s = numeric(),
  ms = numeric(),
  kills = numeric(),
  errors = numeric(),
  total_attacks = numeric(),
  hit_pct = numeric(),
  assists = numeric(),
  aces = numeric(),
  s_err = numeric(),
  digs = numeric(),
  r_err = numeric(),
  block_solos = numeric(),
  block_assists = numeric(),
  b_err = numeric(),
  tb = numeric(),
  total_blocks = numeric(),
  pts = numeric(),
  bhe = numeric(),
  trpl_dbl = numeric()
)

playerstatsfilename <- paste0("data/ncaa_womens_volleyball_playerstats_", season, ".csv")

for (i in urls){
  
  schoolpage <- i %>% read_html()
  
  schoolfull <- schoolpage %>% html_nodes(xpath = '//*[@id="contentarea"]/fieldset[1]/legend/a[1]') %>% html_text()
  
  playerstats <- schoolpage %>% html_nodes(xpath = '//*[@id="stat_grid"]') %>% html_table()
  
  playerstats <- playerstats[[1]] %>% clean_names() %>% filter(jersey != "-") %>% mutate(roster_name = player) %>% separate(player, into=c("last_name", "first_name"), sep=",") %>% mutate(full_name = paste(first_name, last_name, sep=" ")) %>% separate(ht, into=c("feet", "inches"), sep="-") %>% mutate(team = schoolfull, season=season) %>% select(team, season, jersey, full_name, roster_name, everything()) %>% mutate_at(vars(-season, -team, -jersey, -full_name, -roster_name, -first_name, -last_name, -yr, -pos), ~str_replace(., ",", "")) %>% mutate_all(na_if,"") %>% mutate_at(vars(-season, -team, -jersey, -full_name, -roster_name, -first_name, -last_name, -yr, -pos),  replace_na, '0') %>% mutate_at(vars(-season, -team, -jersey, -full_name, -roster_name, -first_name, -last_name, -yr, -pos), as.numeric)
  
  playerstats <- playerstats %>% mutate(points = case_when(max(tb) > 50 ~ tb, max(tb) <= 50 ~ pts)) %>% mutate(tb = case_when(max(tb) < 50 ~ tb, max(tb) >= 50 ~ pts)) %>% select(-pts) %>% rename(pts = points)
  
  playerstatstibble <- playerstatstibble %>% add_row(playerstats)
  
  message <- paste0("Fetching ", schoolfull)
  
  print(message)
  
  Sys.sleep(2)
}

write_csv(playerstatstibble, playerstatsfilename)