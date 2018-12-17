# STA 523 Final Project: Duke Men’s Basketball Player Analysis Application

Our final project for STA 523 is a shiny application that explores Duke Men’s Basketball. Users can select Duke players from the past 13 seasons and look at player-related information. In addition, users can look at the player’s performance over a season in a given statistic, such as points, assists, blocks, steals, and fouls. Finally, the user can select specific games and see information about the date of the game, the opponent, and the final outcome. This app utilizes data from ESPN.com, goduke.com, and wikipedia.com.

This project uses the following concepts learned in class:
1) Web-scraping data
2) Specifying file dependencies using a make file
3) Developing an interactive application using shiny
4) Creating visualizaitons using ggplot
5) Plotting and visualizing spacial data

## How to Run the Application

All you need to do once you clone the repo is type in “make” into the terminal and the Makefile should handle getting all the necessary data. It should take a few minutes to run. It will output an HTML file, but since our final product is a shiny application, the HTML file is negligible. Once the Makefile is done running, open STA523_final_project.Rmd and run the application.

Our app has also been published on shinyapps.io at this URL: https://andyc.shinyapps.io/STA523_final_project/ 

The published version and the version created locally should be identical.

## How the app is made

The project follows a hierarchical structure similar to homework 5. There are three different sources of data: boxscores.rds, games.rds, and player_names.rds. These three data sources are created through web scraping in three R scripts:

### get_boxscores.R
Scrapes player performances in each game of each season from ESPN.com. This includes each player’s performance in points, assists, rebounds, steals, blocks, and fouls.

### get_games.R
Scrapes outcomes of games played during each season from ESPN.com. This includes the date the game was played, the outcome, the opponent, and the number of points scored.  

### get_player_names.R
Scrapes names of players in each season from goduke.com. Includes player-related information like position, jersey number, hometown, height, weight, year, and an image of the player. In addition, the latitude and longitude of each player’s hometown is found using scraped data from wikipedia.

These three data sources are combined and cleaned up in parse_data.R. This script outputs a single data file, players_data.rds, which is used as the single data source for the shiny app.

## How to Use the Application
There are three main features to the application: information on each player, information on each player’s seasonal performance, and information on each game.

### Player Information
The user can select any player that played for Duke from the 2005-2006 season to the 2017-2018 season. The reason the earliest season is 2005-2006 is because that was how far back ESPN had boxscore data available on its website. The reason the latest season is 2017-2018 is because the current season is underway, and scraping data from an unfinished season introduced technical challenges that we decided not to deal with.

The user selects the season, which then updates the roster of players who played in that season. The app then outputs a description of the player, including his position, jersey number, and hometown. The app also outputs an image of the player and a map that plots a point where his hometown is. Note that for players born outside of the United States, the point is plotted outside of the map.

### Player Performance Information
Based on the user-selected season, player, and statistic, a plot of the player’s performance over the course of the season. For instance, if the user selected Alex O’Connell during the 2017-2018 season, and the statistic selected is “Points”, then the plot shows the number of points O’Connell scored in each game he played in during the 2017-2018 season. Points on the plot indicate games, with the color representing the outcome (blue = Duke won, red = Duke lost), and the size of the point representing the deficit (the bigger the circle, the more Duke won/lost by). The blue horizontal line plots that player’s career performance in that statistic. Note that if a player did not play in a game for some reason (e.g. they were injured) then the game will not show up on the plot.

### Game-Related Information
A user can look at game-related information by using the interactivity of the line plot. A user can click on a point on the graph to summon a modal dialog box. This box includes information on the exactly when that game was played, who Duke played against, and the final score. It also gives pictures and statistics on the top 3 players in the selected statistic. So if the user selected “Points”, then it would show the top 3 scorers in that game.

