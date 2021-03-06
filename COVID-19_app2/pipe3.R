#-------------------------------------------------------------#
#-------------------------------------------------------------#
# Pipe line for in-depth US data on COVID-19
#-------------------------------------------------------------#
#-------------------------------------------------------------#
# ===0=== #
source("library.R")
# source("COVID-19_app2/library.R")
# ===1=== #
# Manually made key for US state names and abbreviatsions
uskey <- read.csv("uskey.csv")
# uskey <- read.csv("COVID-19_app2/uskey.csv")
uskey$state <- as.character(uskey$state)
#-------------------------------------------------------------#
# ===2=== #
# https://www.cnn.com/2020/03/23/us/coronavirus-which-states-stay-at-home-order-trnd/index.html
# Constructed a chart from 'investigative' scraping from CNN website
# Data.frame created manually on 2020-04-21 at 7:30pm
stay_home <- read.csv("StayHomeIssueDates.csv")
# stay_home <- read.csv("COVID-19_app2/StayHomeIssueDates.csv")
stay_home$state <- as.character(stay_home$state)
stay_home$date_StayHomeOrder_issued <- as.Date(stay_home$date_StayHomeOrder_issued)
#-------------------------------------------------------------#
# ===3=== #
#KFF data: https://www.kff.org/health-costs/issue-brief/state-data-and-policy-actions-to-address-coronavirus/
cap <- fread("HealthCapacity.csv",fill = T)
# cap <- fread("COVID-19_app2/HealthCapacity.csv",fill = T)

# pol <- fread("PublicPolicy.csv",fill = T)
#-------------------------------------------------------------#
#-------------------------------------------------------------#
#-------------------------------------------------------------#
# ===4=== #
# The followig data comes from https://covidtracking.com/api which collects data

# US aggregate time series data on several variables
usts <- fread("https://covidtracking.com/api/us/daily.csv") %>% 
  select(-13,-14,-16:-24)
usts$date <- as.Date(sapply(as.character(usts$date),function(char){
  yr <- char %>% str_sub(1,4)
  m <- char %>% str_sub(5,6)
  day <- char %>% str_sub(-2,-1)
  return((str_c(yr,"-",m,"-",day)))
}))

#add days
usts <- usts %>% mutate(day = nrow(usts):1) %>% select(day,grep(".",colnames(usts)))

#add cap info
usts$Location <- "United States"
usts <- usts %>% left_join(cap, by = "Location")

usts <- usts %>% mutate(incidence = positive-lead(positive), 
                R0 = incidence/lead(incidence))

#__________________________________________________

# States time series data on several variables
stts <- fread("https://covidtracking.com/api/v1/states/daily.csv") %>% 
  select(-13,-14,-16:-24)
stts$date <- as.Date(sapply(as.character(stts$date),function(char){
  yr <- char %>% str_sub(1,4)
  m <- char %>% str_sub(5,6)
  day <- char %>% str_sub(-2,-1)
  return((str_c(yr,"-",m,"-",day)))
}))

#add state names and cap data
stts <- stts %>% left_join(uskey[-3],by = c("state" = "abb")) %>% 
  left_join(cap, by = c("state.y" = "Location"))

# add stay-at-home order data
stts <- stts %>% left_join(stay_home[-1],by = c("state" = "abb"))

#__________________________________________________

# A data frame about testing in the US
#cdc <- fread("https://covidtracking.com/api/cdc/daily.csv") %>% 
#  mutate(cumulative = cumsum(dailyTotal)*(1-lag))
#-------------------------------------------------------------#
#-------------------------------------------------------------#
#-------------------------------------------------------------#
# ===5=== #
# Run functions for pipe3 data
source("pipe3functions.R")
# source("COVID-19_app2/pipe3functions.R")

pipe3ran <- TRUE

#Examine difference between this account and the john hopkins data
# rev(filter(track("Wisconsin"),date >= "2020-03-04")[['confirms']]) - 
#   (filter(stts,state =='WI')[['positive']]) -> a

#Data for creating maps
library(dplyr)
library(ggplot2)

state_current = read.csv("https://covidtracking.com/api/v1/states/current.csv", header=T)
state_current <- state_current %>% select(state, positive, negative, death)

state_latlon = read.table("https://people.sc.fsu.edu/~jburkardt/datasets/states/state_capitals_ll.txt", header=F)
state_latlon <- state_latlon %>% 
  rename(state = V1) %>% 
  rename(Latitude = V2) %>% 
  rename(Longitude = V3)

state_capitals = read.table("https://people.sc.fsu.edu/~jburkardt/datasets/states/state_capitals_name.txt", header=F)
state_capitals <- state_capitals %>% 
  rename(state = V1) %>% 
  rename(capitals = V2)

# state_names = read.csv("COVID-19_app2/statelatlong.csv", header=T)
state_names = read.csv("statelatlong.csv", header=T)
state_names <- state_names %>% 
  rename(state_abbr = State) %>% 
  rename(state = City) %>% 
  select(state_abbr, state)

state_current <- state_current %>% 
  left_join(state_latlon, by="state") %>% 
  left_join(state_capitals, by="state") %>% 
  filter(!is.na(Latitude)) %>% 
  rename(state_abbr = state) %>% 
  left_join(state_names, by="state_abbr") %>% 
  select(state_abbr, state, capitals, everything())