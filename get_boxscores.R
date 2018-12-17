#This script scrapes boxscores of games from ESPN.com.
#Each page contains a boxscore of a game for both teams.
#Scrapes player names and performances in points, assists, rebounds, steals,
#blocks, and fouls.
#Scrapes data for both Duke players and opposing players. Opposing player
#data is dropped in parse_data.R
#Full names are not given, so they are scraped in get_player_names.R

library(tidyverse)
library(rvest)
library(httr)

#Create data folder
data_dir <- "data/"
dir.create(data_dir, showWarnings = FALSE)

#Function that returns a game's boxscore in a data frame
get_game_stats <- function(season, date, year){
  
  status <- GET(season %>% str_replace("game", "boxscore")) %>% 
    status_code
  if(status == 500 || status == 502){
    return(NULL)
  }
  
  #Read in boxscore page
  page <- read_html(season %>% str_replace("game", "boxscore"))
  
  #Scrape page
  points = page %>% 
    html_nodes(".dnp , td.pts") %>% 
    html_text()
  if("--" %in% points){
    points <- points %>% 
      .[which(. != "--")]
  }else{
    points <- points %>% 
      .[-(which(. == "") - 1)] %>% 
      .[which(. != "")]
  }
  rebounds = page %>% 
    html_nodes(".dnp , td.reb") %>% 
    html_text()
  if("--" %in% rebounds){
    rebounds <- rebounds %>% 
      .[which(. != "--")]
  }else{
    rebounds <- rebounds %>% 
    .[-(which(. == "") - 1)] %>% 
    .[which(. != "")]
  }
  assists = page %>% 
    html_nodes(".dnp , td.ast") %>% 
    html_text()
  if("--" %in% assists){
    assists <- assists %>% 
      .[which(. != "--")]
  }else{
    assists <- assists %>% 
      .[-(which(. == "") - 1)] %>% 
      .[which(. != "")]
  }
  fouls = page %>% 
    html_nodes(".dnp , td.pf") %>% 
    html_text()
  if("--" %in% fouls){
    fouls <- fouls %>% 
      .[which(. != "--")]
  }else{
    fouls <- fouls %>% 
      .[-(which(. == "") - 1)] %>% 
      .[which(. != "")]
  }
  blocks = page %>% 
    html_nodes(".dnp , td.blk") %>% 
    html_text() 
  if("--" %in% blocks){
    blocks <- blocks %>% 
      .[which(. != "--")]
  }else{
    blocks <- blocks %>% 
      .[-(which(. == "") - 1)] %>% 
      .[which(. != "")]
  }
  steals = page %>% 
    html_nodes(".dnp , td.stl") %>% 
    html_text()  
  if("--" %in% steals){
    steals <- steals %>% 
      .[which(. != "--")]
  }else{
    steals <- steals %>% 
      .[-(which(. == "") - 1)] %>% 
      .[which(. != "")]
  }
  
  #Construct data frame of boxscore
  df <- data_frame(
    year = year,
    date = date,
    player = page %>% 
      html_nodes("#gamepackage-boxscore-module a span") %>% 
      html_text() %>% 
      .[c(TRUE, FALSE)],
    points = points,
    rebounds = rebounds,
    assists = assists,
    fouls = fouls,
    blocks = blocks,
    steals = steals
  ) %>% 
    filter(points != "Did not play") %>% 
    mutate(points = points %>% as.numeric(),
           rebounds = rebounds %>% as.numeric(),
           assists = assists %>% as.numeric(),
           fouls = fouls %>% as.numeric(),
           blocks = blocks %>% as.numeric(),
           steals = steals %>% as.numeric()
           )
  return(df)
}

#Gets all boxscore data for given season
get_season <- function(year){
  
  #Read season page
  url <- paste0("http://www.espn.com/mens-college-basketball/team/schedule/_/id/150/season/",
               year)
  page <- read_html(url)
  
  #Scrape season page
  dates <- page %>% 
    html_nodes(".ml4 a , .Table2__td:nth-child(1) span") %>% 
    html_text() %>% 
    .[which(. != "Date")] %>% 
    .[c(TRUE, FALSE)]
  links <- page %>% 
    html_nodes(".ml4 a") %>% 
    html_attr("href")
  
  #Call get_game_stats for each boxscore
  df <- map_df(1:length(links), function(i)
    {get_game_stats(links[i], dates[i], as.character(year))})
  return(df)
}

#Scrape seasons 2005-2018
years <- 2005:2018
boxscores <- map_df(years, function(x){get_season(x)})

#Write data frame to data folder
write_rds(boxscores, path = "data//boxscores.rds")