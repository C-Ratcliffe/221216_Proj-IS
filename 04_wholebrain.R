# preamble####

# environmental variables are cleared, and the console is erased
rm(list = ls())
cat("\014")

# libraries are loaded
library('RNifti')
library('miscTools')
library('ggplot2')
library('tidyr')

# data import and management####
# the code directory is set as the study directory for this script
studydir <- '/Users/coreyratcliffe/Documents/WD_code/rstats/221216_Proj-IS/'
derivdir <- '/Users/coreyratcliffe/Documents/WD_imaging/221216_Proj-IS/derivatives/'
setwd(studydir)
source("00_functions.r")

# dsc####
tab.wbdsc <- read.delim(
	paste0(
		studydir
		, 'resources/wholebrain_dice.tsv'
	)
	, dec = '.'
	, sep = '\t'
	, numerals = 'no.loss'
	, header = T
)
tab.wbdsc[] <- lapply(
	tab.wbdsc
	, as.numeric
	)
tab.dsc <- colMeans(tab.wbdsc)

# icc###
tab.wbicc <- read.delim(
	paste0(
		studydir
		, 'resources/wholebrain_vols.tsv'
	)
	, dec = '.'
	, sep = '\t'
	, numerals = 'no.loss'
	, header = T
)
tab.wbicc[] <- lapply(
	tab.wbicc
	, as.numeric
	)
tab.icc <- tab.dsc
for (i in c(1:4, 6:8)){
	temp <- data.frame(
		tab.wbicc[, i]
		, tab.wbicc[, 5]
		)
	temp.icc <- ICC(
		temp
		, lmer = T
		)
	tab.icc[i] <- temp.icc[[1]][3,2]
}

# vol####

tab.wbvol <- tab.wbicc
tab.vol <- tab.dsc
for (i in c(1:4, 6:8)){
	tab.wbvol[, i] <- (tab.wbvol[, i] - mean(tab.wbvol[, 5])) / sd(tab.wbvol[, 5])
}
tab.vol <- colMeans(tab.wbvol)
tab.all <- rbind(tab.dsc
	, tab.vol
	, tab.icc
	)
row.names(tab.all) <- c('dsc'
	, 'icc'
	,'vol'
	)
print(round(t(tab.all), digits = 2))