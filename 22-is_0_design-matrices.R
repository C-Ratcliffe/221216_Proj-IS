rm(list = ls())
cat("\014")
source("22-is_functions.r")

#Importing the demographics####

ptcvars <- read.delim("resources/participants.csv", dec = ".", sep = ",", numerals = "no.loss")

#Integer encoding - unstandardised####

ptc_int_raw <- ptcvars

##PWE are coded as 1, controls as 0
##Males are coded as 1, females as 0

ptc_int_raw[ptc_int_raw == "IGE"] <- 1
ptc_int_raw[ptc_int_raw == "M"] <- 1
ptc_int_raw[ptc_int_raw == "HC"] <- 0
ptc_int_raw[ptc_int_raw == "F"] <- 0

##t-contrast

###controls > PWE
ptc_int_raw_tcon <- c(-1, 0, 0, 0)

###PWE > controls
ptc_int_raw_tcon <- c(1, 0, 0, 0)

#Integer encoding - standardised####

ptc_int_sd <- ptcvars

##PWE are coded as 1, controls as 0
##Males are coded as 1, females as 0
##Age is standardised

ptc_int_sd[ptc_int_sd == "IGE"] <- 1
ptc_int_sd[ptc_int_sd == "M"] <- 1
ptc_int_sd[ptc_int_sd == "HC"] <- 0
ptc_int_sd[ptc_int_sd == "F"] <- 0
ptc_age_sd <- sqrt((sum((ptcvars$Age_at_Scan - mean(ptcvars$Age_at_Scan))^2))/length(ptcvars$Age_at_Scan))
ptc_int_sd$Age_at_Scan <- (ptcvars$Age_at_Scan - mean(ptcvars$Age_at_Scan))/ptc_age_sd
