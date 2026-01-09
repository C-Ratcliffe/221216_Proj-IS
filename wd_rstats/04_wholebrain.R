# preamble####

# environmental variables are cleared, and the console is erased
rm(list = ls())
cat("\014")

# libraries are loaded
library('RNifti')
library('miscTools')
library('ggplot2')
library('tidyr')
# for icc calculation
library('psych')

# data import and management####
# the code directory is set as the study directory for this script
dir.r <- '/Users/coreyratcliffe/Documents/WD_code/rstats/221216_Proj-IS/'
dir.data <- '/Volumes/LaCie/WD_imaging/221216_Proj-IS/derivatives/'
setwd(dir.r)
source("00_functions.r")

# dsc####
tab.wbdsc <- read.delim(
	paste0(
		dir.r
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
		dir.r
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
for (i in c(1:5, 7:10, 6)){
	temp <- data.frame(
		tab.wbicc[, i]
		, tab.wbicc$iso_fs
		)
	temp.icc <- ICC(
		temp
		, lmer = T
		)
	tab.icc[i] <- temp.icc[[1]][3,2]
}

# vol####
tab.wbvol <- tab.wbicc
for (i in c(1:5, 7:10, 6)){
	tab.wbvol[, i] <- (tab.wbvol[, i] - mean(tab.wbvol$iso_fs)) / sd(tab.wbvol$iso_fs)
}
tab.vol <- colMeans(tab.wbvol)

# final table creation####
tab.all <- data.frame(
	tab.dsc
	, tab.vol
	, tab.icc
	)
colnames(tab.all) <- c(
	'dsc'
	, 'z_diff'
	, 'icc'
	)
print(
	round(
		tab.all
		, digits = 2
		)
	)
