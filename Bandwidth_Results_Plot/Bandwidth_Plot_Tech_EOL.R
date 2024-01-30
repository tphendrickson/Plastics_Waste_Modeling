# Script for plotting Bandwidth End-of-Life general technology flows (from SankeyData.xlsx)
# Author: Tommy Hendrickson (tphendrickson@lbl.gov), 5/19/22

library(ggplot2)
library(tidyverse)
library(pals)

# set directory
setwd("/Users/tphendrickson/Documents/Plastics Data/R Bandwidth Plots")

# load data
Bandwidth_Data = read.csv("Bandwidth_EOL_Type.csv", header = TRUE)
Bandwidth_Long <- Bandwidth_Data %>%
  pivot_longer(cols = c(-Technology.Type), # pivot longer to make data tidy
               names_to = "Scenario",
               values_to = "MMT")

# add in sorting scenario data
Bandwidth_Long$'Sorting Scenario' <- rep(c("Baseline", rep("Constrained Sorting", 3), rep("Unconstrained Sorting", 3)), 7)

Bandwidth_Long$Scenario <- gsub(".", " ", Bandwidth_Long$Scenario, fixed = TRUE) # replace "." with " "
Bandwidth_Long$Scenario <- gsub(" 1", "", Bandwidth_Long$Scenario, fixed = TRUE)
Bandwidth_Long$Scenario <- gsub("  Baseline", "", Bandwidth_Long$Scenario, fixed = TRUE)
Bandwidth_Long$Scenario <- gsub(" ", "\n", Bandwidth_Long$Scenario, fixed = TRUE) # create line breaks in Scenarios
Bandwidth_Long$Scenario <- gsub("State\nof\nthe\nArt", "State of\nthe Art",
                                Bandwidth_Long$Scenario, fixed = TRUE)
Bandwidth_Long$Scenario <- gsub("Current Typical", "Current\n  Typical", Bandwidth_Long$Scenario, fixed = TRUE)
Bandwidth_Long$Scenario <-gsub("Minimum", "Maximum", Bandwidth_Long$Scenario, fixed = TRUE) # formatting for Post-Consumer Resin Stock plot
Bandwidth_Long <- rename(Bandwidth_Long, "Technology Type" = "Technology.Type") # Rename Resin.Type column

#png(file = "EOL_Tech_Type.png", width = 800, height = 600)

EOL_Plot <- ggplot(Bandwidth_Long, aes(fill = `Technology Type`, x = reorder(`Scenario`, MMT), y = MMT)) + # reorder Scenarios to go from highest to lowest
              geom_bar(position = "stack", stat = "identity") + 
              xlab("Scenario") +
              ylab("Million Metric Tons") +
              scale_fill_manual(values = as.vector(watlington(7))) + # set "pals - watlington" palette to 7 EOL Technologies
              #ggtitle("End-of-Life Flows by Techology Type") +
              scale_y_continuous(breaks = seq(0, 60, 10)) +
              facet_grid(cols = vars(`Sorting Scenario`), scales = "free", space = "free", switch = "y") +
              theme_classic() +
              theme(axis.text = element_text(size = 10),
                    axis.title = element_text(size = 10),
                    plot.title = element_text(size = 18, hjust = 0.5),
                    legend.text = element_text(size = 10),
                    legend.title = element_text(size = 10),
                    strip.text.x = element_text(size = 10))

#ggsave(file = "EOL_Tech_Type.svg", plot = EOL_Plot, width = 10, height = 8)

#dev.off()
