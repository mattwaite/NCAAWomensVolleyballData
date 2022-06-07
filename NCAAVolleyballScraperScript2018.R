library(tidyverse)
library(lubridate)
library(rvest)
library(janitor)

urls <- read_csv("url_csvs/NCAA Volleyball - 2018.csv") %>% pull(1)

root_url <- "https://stats.ncaa.org"
season = "2018"
playerstatstibble = tibble()
matchstatstibble = tibble()

playerstatsfilename <- paste0("ncaa_volleyball_playerstats_", season, ".csv")
matchstatsfilename <- paste0("ncaa_volleyball_matchstats_", season, ".csv")

for (i in urls){
  
  schoolpage <- i %>% read_html()
  
  schoolfull <- schoolpage %>% html_nodes(xpath = '//*[@id="contentarea"]/fieldset[1]/legend/a[1]') %>% html_text()
  
  roster_url <- schoolpage %>% html_nodes(xpath = '//*[@id="contentarea"]/a[1]') %>% html_attr('href')
  
  playerstats_url <- schoolpage %>% html_nodes(xpath = '//*[@id="contentarea"]/a[2]') %>% html_attr('href')
  
  matchstats_url <- schoolpage %>% html_nodes(xpath = '//*[@id="contentarea"]/a[3]') %>% html_attr('href')
  
  playerstats <- paste(root_url, playerstats_url, sep="") %>% read_html() %>% html_nodes(xpath = '//*[@id="stat_grid"]') %>% html_table()
  
  tryCatch(playerstats <- playerstats[[1]] %>% filter(Player != "TEAM" & Player != "Totals" & Player != "Opponent Totals") %>% mutate(RosterName = Player) %>% separate(Player, into=c("LastName", "FirstName"), sep=",") %>% mutate(FullName = paste(FirstName, LastName, sep=" ")) %>% separate(Ht, into=c("Feet", "Inches"), sep="-") %>% mutate(Team = schoolfull, Season=season) %>% clean_names() %>% select(team, season, jersey, full_name, roster_name, everything()) %>% mutate_at(10:31, ~str_replace(., ",", "")) %>%  mutate_at(10:31, as.numeric),
           error = function(e){NA})
  
  tryCatch(playerstatstibble <- bind_rows(playerstatstibble, playerstats),
           error = function(e){NA})
  
  matchpage <- paste(root_url, matchstats_url, sep="") %>% read_html() 
  
  matches <- matchpage %>% html_nodes(xpath = '//*[@id="game_breakdown_div"]/table') %>% html_table(fill=TRUE)
  
  tryCatch(matches <- matches[[1]] %>% slice(3:n()) %>% filter(X2 != "Defensive Totals") %>% row_to_names(row_number = 1) %>% remove_empty(which="cols") %>% mutate(Date = mdy(Date), HomeAway = case_when(grepl("@",Opponent) ~ "Away", TRUE ~ "Home"), Opponent = gsub("@ ","",Opponent), WinLoss = case_when(grepl("L", Result) ~ "Loss", grepl("W", Result) ~ "Win"), Result = gsub("L ", "", Result), Result = gsub("W ", "", Result)) %>% separate(Result, into=c("VisitorScore", "HomeScore")) %>% rename(Result = WinLoss) %>% mutate(Team = schoolfull) %>% select(Date, Team, Opponent, HomeAway, Result, everything()) %>% clean_names() %>% mutate_at(vars(-date, -opponent, -home_away, -result, -team), ~str_replace(., "/", "")) %>% mutate_at(vars(-date, -opponent, -home_away, -result, -team), as.numeric),
           error = function(e){NA})
  
  tryCatch(matchstatstibble <- bind_rows(matchstatstibble, matches),
           error = function(e){NA})
  
  Sys.sleep(2)
}

playerstatstibble <- playerstatstibble %>% remove_empty(which="rows")
matchstatstibble <- matchstatstibble %>% remove_empty(which="rows")

write_csv(playerstatstibble, playerstatsfilename)
write_csv(matchstatstibble, matchstatsfilename)