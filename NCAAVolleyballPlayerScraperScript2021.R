library(tidyverse)
library(lubridate)
library(rvest)
library(janitor)

urls <- read_csv("url_csvs/NCAA Volleyball - 2021.csv") %>% pull(1)

root_url <- "https://stats.ncaa.org"
season = "2021"

playerurls <- tibble()

playermatchstatstibble = tibble()
playercareerstatstibble = tibble()

playermatchstatsfilename <- paste0("data/ncaa_volleyball_playermatchstats_", season, ".csv")

playercareerstatsfilename <- paste0("data/ncaa_volleyball_playercareerstats_", season, ".csv")

for (i in urls){
  
  schoolpage <- i %>% read_html()
  
  schoolfull <- schoolpage %>% html_nodes(xpath = '//*[@id="contentarea"]/fieldset[1]/legend/a[1]') %>% html_text()
  
  roster_url <- schoolpage %>% html_nodes(xpath = '//*[@id="contentarea"]/a[1]') %>% html_attr('href')
  
  playerstats_url <- schoolpage %>% html_nodes(xpath = '//*[@id="contentarea"]/a[2]') %>% html_attr('href')
  
  gamestats_url <- schoolpage %>% html_nodes(xpath = '//*[@id="contentarea"]/a[3]') %>% html_attr('href')
  
  playermatchurllist <- paste(root_url, playerstats_url, sep="") %>% read_html() %>% html_nodes(xpath = '//*[@id="stat_grid"]') %>% html_elements("a") %>%
    html_attr('href') %>%
    as_tibble() %>%
    mutate(value = paste0("https://stats.ncaa.org", value))
  
  playerurls <- bind_rows(playerurls, playermatchurllist)
  
  Sys.sleep(2)
}

playermatchurls <- pull(playerurls, 1)

for (i in playermatchurls){
  
  playerpage <- i %>% read_html()
  
  schoolfull <- playerpage %>% html_nodes(xpath = '//*[@id="contentarea"]/fieldset[1]/legend/a[1]') %>% html_text()
  
  playerfull <- playerpage %>% html_nodes(xpath="//option[@selected]") %>% html_text()
  
  playerfull <- playerfull[3]
  
  playercareerstats <- playerpage %>% html_nodes(xpath = '/html/body/div[2]/table') %>% html_table()
  
  playercareerstats <- playercareerstats[[1]] %>% slice(3:n())  %>% row_to_names(row_number = 1) %>% remove_empty(which="cols") %>% clean_names() %>% mutate(team = schoolfull, player = playerfull) %>% mutate_at(vars(-year, -team, -player), ~str_replace(., ",", "")) %>% mutate_at(vars(-year, -team, -player), as.numeric) %>% separate(player, into=c("player", "remaining"), sep=" #") %>% separate(remaining, into=c("jersey", "position"), sep=" ") %>% select(year, team, player, jersey, position, everything())
  
  playermatchstats <- playerpage %>% html_nodes(xpath = '/html/body/div[2]/div[3]/table') %>% html_table()
  
  playermatchstats <- playermatchstats[[1]] %>% slice(3:n()) %>% filter(X2 != "Defensive Totals") %>% row_to_names(row_number = 1) %>% remove_empty(which="cols") %>% mutate(Date = mdy(Date), HomeAway = case_when(grepl("@",Opponent) ~ "Away", TRUE ~ "Home"), Opponent = gsub("@ ","",Opponent), WinLoss = case_when(grepl("L", Result) ~ "Loss", grepl("W", Result) ~ "Win"), Result = gsub("L ", "", Result), Result = gsub("W ", "", Result)) %>% separate(Result, into=c("VisitorScore", "HomeScore")) %>% rename(Result = WinLoss) %>% mutate(Team = schoolfull, Player = playerfull) %>% clean_names() %>% mutate_at(vars(-date, -opponent, -home_away, -result, -team, -player), ~str_replace(., "/", "")) %>% mutate_at(vars(-date, -opponent, -home_away, -result, -team, -player), ~str_replace(., ",", "")) %>% mutate_at(vars(-date, -opponent, -home_away, -result, -team, -player), as.numeric) %>% separate(player, into=c("player", "remaining"), sep=" #") %>% separate(remaining, into=c("jersey", "position"), sep=" ") %>% select(date, team, player, jersey, position, opponent, home_away, result, everything())  

  tryCatch(playercareerstatstibble <- bind_rows(playercareerstatstibble, playercareerstats),
           error = function(e){NA})
  
  tryCatch(playermatchstatstibble <- bind_rows(playermatchstatstibble, playermatchstats),
           error = function(e){NA})
}

playercareerstatstibble <- playercareerstatstibble %>% remove_empty(which=c("rows", "cols"))
playermatchstatstibble <- playermatchstatstibble %>% remove_empty(which=c("rows", "cols"))

write_csv(playercareerstatstibble, playercareerstatsfilename)
write_csv(playermatchstatstibble, playermatchstatsfilename)