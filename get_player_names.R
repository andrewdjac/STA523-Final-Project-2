library(tidyverse)
library(rvest)

data_dir <- "data/"
dir.create(data_dir, showWarnings = FALSE)

get_player_names = function(season){
  base_url = "http://www.goduke.com/SportSelect.dbml?DB_OEM_ID=4200&SPID=1845&SPSID=22727&KEY=&Q_SEASON="
  url = paste0(base_url, as.character(season))
  page = read_html(url)
  number = page %>% html_nodes(".number") %>% html_text()
  index = (length(number)-1)/2
  leng = (length(number)+1)/2
  number = number[1:index]
  if (season >= 2009){
    name = page %>% html_nodes(".showPopup") %>% html_text()}
  if (season < 2009){
    name     = page %>% html_nodes(".name") %>% html_text() %>% .[2:leng]}
  position = page %>% html_nodes(".position") %>% html_text() %>% .[1:index]
  height   = page %>% html_nodes(".height") %>% html_text() %>% .[1:index]
  weight   = page %>% html_nodes(".weight") %>% html_text() %>% .[2:leng]
  year     = page %>% html_nodes(".year") %>% html_text() %>% .[1:index]
  home     = page %>% html_nodes(".hometown") %>% html_text() %>% .[1:index]
  seas     = paste0(as.character(season),"-",as.character(season + 1))
  img_url  = page %>% html_nodes("#roster-list-table a") %>% html_attr("href") %>% 
    paste0("http://goduke.com", .)
  img      = img_url %>% 
    map(function(x){read_html(x) %>% html_nodes("#bio-player-img") %>% html_attr("src")}) %>% unlist()
  info = data.frame(
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
  
  info = info %>% mutate(
    Number = Number %>% as.character(),
    Position = str_remove_all(Position, "Position:\\s|\\t|\\n"),
    Height = str_remove_all(Height, "\\n|\\t|\\d\\d\\d\\slbs"),
    Weight = str_remove_all(Weight, "\\t|\\n"),
    Year = str_remove_all(Year, "\\t|\\n|Year:\\s") %>%
      plyr::mapvalues(from=c("Fr.", "So.", "Jr.", "Sr.","RFr.","RSo.","RJr.","RSr."), 
                      to=c("Freshman", "Sophomore", "Junior", "Senior", 
                           "Redshirt Freshman","Redshirt Sophomore", "Redshirt Junior", "Redshirt Senior"),
                      warn_missing = FALSE),
    Hometown = str_remove_all(Hometown, "\\t|\\n|Hometown:\\s"))
  
  info$Name = str_remove_all(info$Name, "\\t|\\n") %>% substr(.,nchar(.)/2+1,nchar(.))
  return (info)
}

seasons = c(2005:2018)

player_names = data.frame()
for (season in seasons){
  df = get_player_names(season)
  player_names = rbind(player_names, df)
}

player_names <- player_names %>% 
  mutate(player = Name %>% str_replace(., "[^A-Z]+", ". ")) %>% 
  rename(season = Season)

player_names[player_names$player == "J. J. Redick", "player"] <- "J. Redick"

write_rds(player_names, path = "data//player_names.rds")