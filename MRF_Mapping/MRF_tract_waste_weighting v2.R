# National MRF data - determining per capita flows at MRFs based on nearest census tracts
# For plot 1, scaled to each tract to determine weighted (by population) flows from each tract to MRF
# For plot 2, we calculate the total plastic waste to MRFs, and then what the share of plastic waste to MRFs is of total plastic waste generated
# Author: Tommy Hendrickson (tphendrickson@lbl.gov)
# Last updated: 11/10/22

library(tidyverse)
library(sf)
library(tmap)
library(viridis)

# Set working directory
setwd("/Users/tphendrickson/Documents/Plastics Data/BioSiting Plots")

# Load tract data for plastic waste flows to the nearest MRF
# Data reflects for each tract what the nearest MRF is, and what the waste flows (short tons per day) are at that MRF
# Original data came from Tyler Huntington (plastics_recovered_by_us_census_tract.csv)
Tract_MRF_data = read.csv("plastics_recovered_by_us_census_tract_short.csv", header = TRUE)

# Recast GEOID column to character to repair data
Tract_MRF_data$GEOID <- as.character(Tract_MRF_data$GEOID)

# Loop through GEOIDs and add back in missing zero's from start of some GEOIDs
for(i in 1:nrow(Tract_MRF_data)){
  if(nchar(Tract_MRF_data[i, 2]) < 11) {
    Tract_MRF_data[i, 2] <- paste("0", Tract_MRF_data[i, 2], sep = "")
  }
}

# Create per capita tonnage flows and add back in GEOIDs
Tract_MRF_per_capita <- Tract_MRF_data[, 3:12]/Tract_MRF_data[, 14]
Tract_MRF_per_capita <- cbind(select(Tract_MRF_data, GEOID), Tract_MRF_per_capita)

# Load population by tract data (downloaded from https://screeningtool.geoplatform.gov/en/downloads)
US_tracts = st_read(dsn = "us_census_tracts/usa.shp")

# Get only continental US data
US_tracts_continental <- US_tracts %>%
  filter(SF != "Alaska",
         SF != "Hawaii",
         SF != "American Samoa",
         SF != "Puerto Rico",
         SF != "Northern Mariana Islands")

# Pull Population (TPF column) separately, as combining that with the geometry has given us problems in the past
US_tracts_population <- US_tracts_continental %>%
  select(GEOID10, TPF)

US_tracts_population <- st_drop_geometry(US_tracts_population)

# Get geometries for tracts separately
US_tracts_geometry <- US_tracts_continental %>%
  select(GEOID10, geometry)

# Prepare and merge shapefile and MRF dataset
Tract_MRF_per_capita <- rename(Tract_MRF_per_capita, GEOID10 = GEOID) # rename GEOID to match shapefile
Tract_MRF_per_capita$GEOID10 <- as.factor(Tract_MRF_per_capita$GEOID10) # recast GEOID10 to match shapefile

US_tracts_MRFs_joined <- left_join(US_tracts_population, Tract_MRF_per_capita, by = "GEOID10") # merge files

# Find tonnage flow at each tract by multiplying per capita with population, then add back in GEOIDs and population
Tract_MRF_tonnage <- US_tracts_MRFs_joined[, 2]*US_tracts_MRFs_joined[, 3:12]
Tract_MRF_tonnage <- cbind(select(US_tracts_MRFs_joined, GEOID10, TPF), Tract_MRF_tonnage)

# Calculate total plastic waste by tract with tract population data
# Total US plastic waste is from EPA Facts and Figures (35,680 kST, 2018 values)
# Total population from US Census (380M for 2018)
Tract_MRF_tonnage <- Tract_MRF_tonnage[, -12] # drop old total plastics columns that has missing data
Tract_MRF_tonnage$Total_Plastic_tpd <- Tract_MRF_tonnage[, 2]*((35680*10^3)/365/(380*10^6))*0.907185 #final term is conversion from ST to MT

# Calculate total plastic waste flows to MRF by tract with tract population data and total_MRF_plastics_tpd (in per capita form)
Tract_MRF_tonnage$Share_MRF <- ((Tract_MRF_tonnage$total_MRF_plastics_tpd*0.907185)/Tract_MRF_tonnage$Total_Plastic_tpd)*100 #converted total_MRF_plastics_tpd to MT

# Replace NA's with 0's, in case those are messing up the log scale
#Tract_MRF_tonnage <- Tract_MRF_tonnage %>% 
#  replace(is.na(.), 0)

# Replace 0's with very small values to plot log scale
#for(i in 1:nrow(Tract_MRF_tonnage)){
#  if(Tract_MRF_tonnage[i, 12] == 0) {
#    Tract_MRF_tonnage[i, 12] = .0001
#  }
#  if(Tract_MRF_tonnage[i, 13] == 0) {
#    Tract_MRF_tonnage[i, 13] = .01
#  }
#}

# Merge tract geometry with waste flows
US_waste_tracts <- left_join(US_tracts_geometry, Tract_MRF_tonnage, by = "GEOID10")

# Create shape file from combined
US_waste_tracts$geometry <- st_make_valid(US_waste_tracts$geometry)

Tract_MRF_sf <- st_as_sf(US_waste_tracts, sf_column_name = "geometry")

# Create the static choropleth plot for total plastic waste by tract
png(file = "Total_Plastic_Waste_MT.png", width = 1600, height = 1200)

tmap_mode('plot')
tm_shape(Tract_MRF_sf) + 
  tm_fill(col = 'Total_Plastic_tpd',
          #title = "Total Plastic Waste (MT per day)",
          breaks = c(0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 1, 1.1, 
                   1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2, 2.5, 5, 10, 15, 20),
          style = "fixed",
          palette = viridis(20),
          legend.hist = TRUE
          ) +
  tm_layout(legend.outside = TRUE,
            #legend.title.size = 1.2,
            legend.text.size = 1.2)

dev.off()

# Create the static choropleth plot for share of plastic waste going to MRFs
png(file = "Share_MRFs_Plastic_Waste.png", width = 1600, height = 1200)

tmap_mode('plot')
tm_shape(Tract_MRF_sf) + 
  tm_fill(col = 'Share_MRF',
          #title = "Percent of Plastic Waste to MRFs",
          breaks = c(0, 2, 4, 6, 8, 10, 15, 20, 30, 40, 50, 60, 100),
          style = "fixed",
          palette = viridis(20),
          legend.hist = TRUE
          ) +
  tm_layout(legend.outside = TRUE,
            #legend.title.size = 1.2,
            legend.text.size = 1.2)

dev.off()

