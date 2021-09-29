library(tidyverse)
library(magrittr)
library(readxl)

# Set up a working directory with the file validation in it.

#setwd("filepath to pfia_validation.xlsx")

#### Load data ####
data <- read_excel("pfia_validation.xlsx", range = "A1:G11")

neun <- data[data$marke == 'neun',]

pv <- data[data$marke == 'pv',]

#### Data cleaning and wrangling ####
data_clean <- data %>% pivot_longer(!c("img_name", "marker"), names_to = "method", values_to = "count")

data_clean$method <- factor(data_clean$method, c("JSA", "ES", "OrdinarySegmentation_Find Maxima", "Stardist", "combined"))

#### Plotting neun data ####
data_clean %>% filter(marker == "neun",) %>% 
  ggplot(aes(method, count, colour = method)) + 
  geom_jitter(size = 3.5, alpha = 0.4, width = 0.15) + 
  geom_line(aes(group = img_name), colour = 'grey', alpha = 0.4) +
  scale_colour_discrete(labels = c('Senior\nresearch\ntrainee', 'Junior\nresearch\ntrainee','Autothresholding\nFind Maxima', 'Stardist', 'Stardist +\nSenior research\ntrainee')) +
  scale_y_continuous(limits = c(0,4000)) + 
  scale_x_discrete(labels = c('Senior\nresearch\ntrainee', 'Junior\nresearch\ntrainee','Autothresholding\nFind Maxima', 'Stardist', 'Stardist +\nSenior research\ntrainee')) + 
  labs(x = 'Method', y = 'Cell count') +
  theme_bw(base_size = 16) +
  theme(legend.position = "none",
        panel.border = element_blank(),
        axis.line = element_line(colour = "black"))

#### Descriptive/Summary statistics ####
data_clean %>% group_by(method, marker) %>%  summarise(avg = mean(count), stand_dev = sd(count)) %>% knitr::kable()

#### NHST ####
neun_aov <- aov(data = data_clean[data_clean$marker == 'neun',], count ~ method)

summary(neun_aov)

TukeyHSD(neun_aov)  # Only run if aov F value is signficant for a p-value threshold of 0.05

#### Plotting pv data ####
data_clean %>% filter(marker == "pv",) %>% 
  ggplot(aes(method, count, colour = method)) + 
  geom_point(size = 3.5, alpha = 0.4) + 
  geom_line(aes(group = img_name), colour = 'grey', alpha = 0.4) +
  scale_colour_discrete(labels = c('Senior\nresearch\ntrainee', 'Junior\nresearch\ntrainee','Autothresholding\nFind Maxima', 'Stardist', 'Stardist +\nSenior research\ntrainee')) +
  scale_y_continuous(limits = c(0,350)) + 
  scale_x_discrete(labels = c('Senior\nresearch\ntrainee', 'Junior\nresearch\ntrainee','Autothresholding\nFind Maxima', 'Stardist', 'Stardist +\nSenior research\ntrainee')) + 
  labs(x = 'Method', y = 'Cell count') +
  theme_bw(base_size = 16) +
  theme(legend.position = "none",
        panel.border = element_blank(),
        axis.line = element_line(colour = "black"))

#### NHST ####
pv_aov <- aov(data = data_clean[data_clean$marker == 'pv',], count ~ method)

summary(pv_aov)

# TukeyHSD(pv_aov) # Only run if aov F value is significant for a p-value threshold of 0.05

# Estimation statistics with dabestr ####

# install.packages("dabestr") # uncomment if the package is not installed in the system
library(dabestr)

est_stats_neun <- data_clean %>% filter(marker == "neun") %>% dabest(method, count, 
                    idx = list(c("JSA", "ES","OrdinarySegmentation_Find Maxima", "Stardist", "combined")),
                    paired = TRUE, id.col = method)

est_stats_diff_neun <- est_stats_neun %>% mean_diff() # saves analysis as object

est_stats_diff_neun # returns value in console

# Cummings estimation plot: neun ####
plot(est_stats_diff_neun,
     rawplot.ylabel = "Cell count",
     effsize.ylabel = "Paired difference\nto Senior researcher")


est_stats_pv <- data_clean %>% filter(marker == "pv") %>% dabest(method, count, 
                                                                 idx = list(c("JSA", "ES","OrdinarySegmentation_Find Maxima", "Stardist", "combined")),
                                                                 paired = TRUE, id.col = method)

est_stats_diff_pv <- est_stats_pv %>% mean_diff() # saves analysis as object

est_stats_diff_pv # returns value in console

plot(est_stats_diff_pv,
     rawplot.ylabel = "Cell count",
     effsize.ylabel = "Paired difference\nto Senior research trainee")
