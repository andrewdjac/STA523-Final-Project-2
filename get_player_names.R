#This script scrapes player names from goduke.com.
#Each page contains a roster of player names for a single season.
#Each player's names is scraped along with player-related info, including
#Height, weight, position, year, hometown, and jersey number.
#Player images are also scraped from goduke.
#Finally, coordinates of each player's hometown are found from wikipedia.

library(tidyverse)
library(rvest)
library(measurements)

#Create data folder
data_dir <- "data/"
dir.create(data_dir, showWarnings = FALSE)

#Function that returns data frame of player info for given season
get_player_names <- function(season){
  
  #Get roster page
  base_url <- "http://www.goduke.com/SportSelect.dbml?DB_OEM_ID=4200&SPID=1845&SPSID=22727&KEY=&Q_SEASON="
  url      <- paste0(base_url, as.character(season))
  page     <- read_html(url)
  
  #Scrape roster page
  number   <- page %>% html_nodes(".number") %>% html_text()
  index    <- (length(number)-1)/2
  leng     <- (length(number)+1)/2
  number   <- number[1:index]
  name     <- page %>% html_nodes("#roster-list-table a") %>% html_text()
  position <- page %>% html_nodes(".position") %>% html_text() %>% .[1:index]
  height   <- page %>% html_nodes(".height") %>% html_text() %>% .[1:index]
  weight   <- page %>% html_nodes(".weight") %>% html_text() %>% .[2:leng]
  year     <- page %>% html_nodes(".year") %>% html_text() %>% .[1:index]
  home     <- page %>% html_nodes(".hometown") %>% html_text() %>% .[1:index]
  seas     <- paste0(as.character(season),"-",as.character(season + 1))
  img_url  <- page %>% html_nodes("#roster-list-table a") %>% 
    html_attr("href") %>% 
    paste0("http://goduke.com", .)
  img      <- img_url %>% 
    map(function(x){read_html(x) %>% 
        html_nodes("#bio-player-img") %>% 
        html_attr("src")}) %>% 
    unlist()
  
  #Construct data frame of player info
  info <- data.frame(
    Season   = seas,
    Number   = number,
    Name     = name,
    Position = position,
    Height   = height,
    Weight   = weight,
    Year     = year,
    Hometown = home,
    Picture  = img
  )
  
  #Clean scraped data
  info <- info %>% mutate(
    Number = Number %>% as.character(),
    Position = str_remove_all(Position, "Position:\\s|\\t|\\n"),
    Height = str_remove_all(Height, "\\n|\\t|\\d\\d\\d\\slbs"),
    Weight = str_remove_all(Weight, "\\t|\\n"),
    Year = str_remove_all(Year, "\\t|\\n|Year:\\s") %>%
      plyr::mapvalues(from=c("Fr.", "So.", "Jr.", "Sr.",
                             "RFr.","RSo.","RJr.","RSr."), 
                      to=c("Freshman", "Sophomore", "Junior", "Senior", 
                           "Redshirt Freshman","Redshirt Sophomore", 
                           "Redshirt Junior", "Redshirt Senior"),
                      warn_missing = FALSE),
    Hometown = str_remove_all(Hometown, "\\t|\\n|Hometown:\\s")
    )
  
return(info)
}

#Scrape seasons 2005-2018
seasons <- c(2005:2018)
player_names <- map_df(seasons, function(season){get_player_names(season)})

#Extract each player's hometown state and city
for(i in 1:nrow(player_names)){
  start_index <- str_locate(player_names$Hometown[i], ",\\s")[1,2]
  end_index <- str_locate(player_names$Hometown[i], "\\(")[1,1]
  player_names$state[i] <- substr(player_names$Hometown[i],
                                  start_index+1,end_index-2)
  if(player_names$state[i] %in% c("Ala.", "Ariz.","Ark.", "Calif.", "Colo.",
                                  "Conn.","Del.","Fla.","Ga.","Ill.", "Ind.",
                                   "Kan.", "Ky.","La.","Md.","Mass.","Mich.",
                                  "Minn.","Miss.", "Mo.","Nev.", "N.J.",
                                   "N.M.","N.Y.","N.C.", "Okla.", "Pa.",
                                  "R.I.", "S.C.","Tenn.", "Vt.","Va.","Texas",
                                  "Ohio", "Utah", "D.C.", "Alaska", "Ore.",
                                  "Ill.\\s")){
    player_names$state[i] <- player_names$state[i] %>% 
      plyr::mapvalues(from=c("Ala.", "Ariz.","Ark.", "Calif.", "Colo.",
                             "Conn.","Del.","Fla.","Ga.","Ill.", "Ind.",
                             "Kan.", "Ky.","La.","Md.","Mass.","Mich.",
                             "Minn.","Miss.", "Mo.","Nev.", "N.J.",
                             "N.M.","N.Y.","N.C.", "Okla.", "Pa.","R.I.", 
                             "S.C.","Tenn.", "Vt.","Va.", "Texas", "Ohio", 
                             "Utah", "D.C.", "Alaska", "Ore.","Ill.\\s"), 
                      to=c(",_Alabama", ",_Arizona",",_Arkansas", 
                           ",_California", ",_Colorado", 
                           ",_Connecticut",",_Delaware", ",_Florida", 
                           ",_Georgia",",_Illinois", ",_Indiana",",_Kansas",
                           ",_Kentucky", ",_Louisiana", ",_Maryland",
                           ",_Massachusetts", ",_Michigan",",_Minnesota", 
                           ",_Mississippi",",_Missouri",",_Nevada",
                           ",_New_Jersey",",_New_Mexico",",_New_York",
                           ",_North_Carolina", ",_Oklahoma", 
                           ",_Pennsylvania",",_Rhode Island", 
                           ",_South_Carolina", ",_Tennessee", ",_Vermont",
                           ",_Virginia", ",_Texas", ",_Ohio", ",_Utah", 
                           ",_D.C.", ",_Alaska", ",_Oregon",",_Illinois"),
                      warn_missing = FALSE)}
  else{
    player_names$state[i] <- ""
  }
  
  player_names$city[i] <- substr(player_names$Hometown[i],1,start_index-2)
}

#Get each player's hometown coordinates from wikipedia
for(i in 1:nrow(player_names)){
  wiki_url = "https://en.wikipedia.org/wiki/"
  full_wiki = paste0(wiki_url, as.character(player_names$city[i]), 
                     as.character(player_names$state[i]))
  if(RCurl::url.exists(full_wiki)){
    wiki_page = read_html(full_wiki)
    if(identical(wiki_page %>% 
                 html_nodes("#coordinates .latitude") %>% 
                 html_text(), character(0)) == FALSE |
       identical(wiki_page %>% 
                 html_nodes("#coordinates .longitude") %>% 
                 html_text(), character(0)) == FALSE){
      player_names$lati[i] = wiki_page %>% 
        html_nodes("#coordinates .latitude") %>% html_text()
      player_names$long[i] = wiki_page %>% 
        html_nodes("#coordinates .longitude") %>% html_text()}}
  else{
    player_names$lati[i] <- "N/A"
    player_names$long[i] <- "N/A"
  }
}

#Clean up scraped coordinates
player_names$lati <- gsub('°', ' ',  player_names$lati)
player_names$lati <- gsub('′', ' ',  player_names$lati)
player_names$lati <- gsub('″', ' ',  player_names$lati)
player_names$lati <- gsub(' N', '',  player_names$lati)
player_names$lati <- gsub(' S', '',  player_names$lati)

player_names$long <- gsub('°', ' ',  player_names$long)
player_names$long <- gsub('′', ' ',  player_names$long)
player_names$long <- gsub('″', ' ',  player_names$long)
player_names$long <- gsub(' W', ' ', player_names$long)
player_names$long <- gsub(' E', '',  player_names$long)

#Convert coordinates to proper units
for(i in 1:nrow(player_names)){
  if(player_names$lati[i] != "N/A" | player_names$long[i] != "N/A"){
    player_names$lat[i] <- measurements::conv_unit(player_names$lati[i], 
                                                  from = 'deg_min_sec', 
                                                  to = 'dec_deg')
    player_names$lon[i] <- measurements::conv_unit(player_names$long[i], 
                                                  from = 'deg_min_sec', 
                                                  to = 'dec_deg')
  }
  else{
    player_names$lat[i] <- "N/A"
    player_names$lon[i] <- "N/A"
  }
}

#Create abbreviated form of players' names for merge with boxscores.rds
player_names <- player_names %>% 
  mutate(player = Name %>% 
           str_replace(., "[^A-Z]+", ". ") %>% 
           str_replace(., ",", ""),
         lat = lat %>% as.numeric(),
         lon = lon %>% as.numeric()) %>% 
  rename(season = Season) %>% 
  select(-lati, -long)

#Manually change two players' names to handle data discrepancy
player_names[player_names$player == "J. J. Redick", "player"] <- "J. Redick"
player_names[player_names$Name == "DeMarcus Nelson", "player"] <- "D. Nelson"

#Write data frame to data folder
write_rds(player_names, path = "data//player_names.rds")