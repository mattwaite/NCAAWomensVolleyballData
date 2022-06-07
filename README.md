# NCAA Women's Volleyball Data

A repository of NCAA women's volleyball data scraped from stats.ncaa.org, including the scrapers written in R.

## Background

Getting data on college sports beyond football and basketball isn't easy, and the NCAA doesn't help matters. Their stats portal, stats.ncaa.org, is ancient, slow and not terribly conducive to analysis. They have added some features to download data to csvs, but the data remains limited to a season, or a team. They expose so much more data on their site, but the only way to get it is to scrape it. So here we are. 

## What's included

Currently, there are scrapers for the 2018-2021 seasons of women's volleyball. The NCAA has data going back a little further, but stats.ncaa.org breaks on certain years -- 2017 and 2015 specifically -- and data before 2014 is less reliable. 

The data exposed on the site can be categorized into three buckets:

1. Team stats for each match of a season. Those can be summarized into season totals for the team. 
2. Player stats for the season. 
3. Player stats for each match of the season.
4. Player stats for their career. 

The first and second items on that list are exposed easily, and the NCAAVolleyballScraperScript20XX.R files specifically scrape those two datasets. 

The second two items require *significantly* more time to gather -- the list of players has to be gathered for each team, then each player page has to be accessed, with a 2 second pause between each request to avoid overwhelming the site with requests. Thus, those are in separate scripts: NCAAVolleyballPlayerScraperScript20XX.R

## What's planned

* During the coming 2022 season, I intend to update this weekly on a day be determined.
* It appears the NCAA uses some kind of ID numbers for teams and players that you can see in URL strings. May be worth parsing the URLS to get those identifiers to make joining easier. Joining can be done now with name, team and jersey number, but in the age of the transfer portal, this isn't going to be perfect. 
