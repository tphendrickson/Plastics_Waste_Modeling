# Script for plotting Bandwidth Assessment data (from SankeyData.xlsx)
# For plotting flows to landfills and post-consumer resin stocks
# Author: Tommy Hendrickson (tphendrickson@lbl.gov), 5/17/22

library(ggplot2)
library(tidyverse)
library(pals)
library(svglite)

# set directory
setwd("/Users/tphendrickson/Documents/Plastics Data/R Bandwidth Plots")

# load data
Bandwidth_Data = read.csv("Bandwidth_Data_Landfill_Flows.csv", header = TRUE)
Bandwidth_Long <- Bandwidth_Data %>%
  pivot_longer(cols = c(-Resin.Type), #-Flow_Type), # pivot longer to make data tidy, add scenarios to cols as necessary
               names_to = "Scenario",
               values_to = "MMT")

# add in sorting scenario data
Bandwidth_Long$'Sorting Scenario' <- rep(c("Baseline", rep("Constrained Sorting", 3), rep("Unconstrained Sorting", 3)), 17)

Bandwidth_Long$Scenario <- gsub(".", " ", Bandwidth_Long$Scenario, fixed = TRUE) # replace "." with " "
Bandwidth_Long$Scenario <- gsub(" Baseline", "", Bandwidth_Long$Scenario, fixed = TRUE)
Bandwidth_Long$Scenario <- gsub(" 1", "", Bandwidth_Long$Scenario, fixed = TRUE)
Bandwidth_Long <- filter(Bandwidth_Long, Scenario != "Theoretical Minimum") # comment this out if plotting post-consumer resin stocks 
                                                                            # (removes theoretical min/max from flows to landfill)
Bandwidth_Long$Scenario <- gsub(" ", "\n", Bandwidth_Long$Scenario, fixed = TRUE) # create line breaks in Scenarios
Bandwidth_Long$Scenario <- gsub("State\nof\nthe\nArt", "State of\nthe Art",
                                Bandwidth_Long$Scenario, fixed = TRUE)
Bandwidth_Long$Scenario <- gsub("Current Typical", "Current\n  Typical", Bandwidth_Long$Scenario, fixed = TRUE) # formatting for Flows to Landfill plot
#Bandwidth_Long$Scenario <-gsub("Minimum", "Maximum", Bandwidth_Long$Scenario, fixed = TRUE) # formatting for Post-Consumer Resin Stock plot
Bandwidth_Long <- rename(Bandwidth_Long, "Resin Type" = "Resin.Type") # Rename Resin.Type column

Bandwidth_Long$Scenario_Sorted <- factor(Bandwidth_Long$Scenario,
                                         levels = c("Current\nTypical\n\n",
                                                    "State of\nthe Art",
                                                    "Practical\nMinimum"))
                                                    #"Theoretical\nMaximum")) # Edit ordering as needed for plot
                                                                             # Note: max/min language need to be changed depending on plot

#png(file = "Post-Consumer_Resin_Stock.png", width = 800, height = 600)

Bandwidth_Plot = ggplot(Bandwidth_Long, aes(fill = `Resin Type`, x = Scenario_Sorted, y = MMT)) +
                    geom_bar(position = "stack", stat = "identity") + 
                    xlab("Scenario") +
                    ylab("Million Metric Tons Landfilled / Year") + #PCR plot is "Million Metric Tons Available / Year
                    expand_limits(y = c(0, 40)) + #comment this out for PCR plot, which sets the correct maximum automatically
                    scale_fill_manual(values = as.vector(alphabet(17))) + # set "pals - alphabet" palette to 17 resin categories
                    #ggtitle("Flows to Landfills") + # change title depending on plot
                    facet_grid(cols = vars(`Sorting Scenario`), scales = "free", space = "free", switch = "y") +
                    theme_classic() +
                    theme(axis.text = element_text(size = 10, face = "bold"),
                          axis.title = element_text(size = 10, face = "bold"),
                          plot.title = element_text(size = 18, hjust = 0.5),
                          legend.text = element_text(size = 10),
                          legend.title = element_text(size = 13),
                          strip.text.x = element_text(size = 12))

ggsave(file = "Flows_to_Landfill.svg", plot = Bandwidth_Plot, width = 10, height = 8)
#dev.off()
