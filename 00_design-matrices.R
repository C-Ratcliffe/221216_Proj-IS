# preamble####

# environmental variables are cleared, and the console is erased
rm(list = ls())
cat("\014")

# data import and management####
# the code directory is set as the study directory for this script
studydir <- '/Users/coreyratcliffe/Documents/WD_code/rstats/221216_Proj-IS/'
derivdir <- '/Users/coreyratcliffe/Documents/WD_imaging/221216_Proj-IS/derivatives/'
setwd(studydir)
source("00_functions.r")

#Importing the demographics
ptcvars <- read.delim(
	'resources/participants.tsv'
	, dec = '.'
	, sep = '\t'
	, numerals = 'no.loss'
	)

# matrix creation####
# the grouping variable is one-hot coded and reordered into HC, IGE, DRE
temp.group <- model.matrix(
	~ group - 1
	, data = ptcvars
	)[, c(2, 3, 1)]
# stored as a continuous variable, then z-scored
temp.age <- (ptcvars$age - mean(ptcvars$age))/sd(ptcvars$age)
# females = 0, males = 1, z-scored to maintain consistency
temp.sex <- (ptcvars$sex - mean(ptcvars$sex))/sd(ptcvars$sex)
# FS eTIV stored as a continuous variable, then z-scored
temp.tpv <- (ptcvars$tpv - mean(ptcvars$tpv))/sd(ptcvars$tpv)
# the design matrix is created (columnwise)
txt.design <- data.frame(
	temp.group
	, temp.age
	, temp.sex
	, temp.tpv
	)
# the design matrix is written out to the stats folder in derivatives
write.table(
	txt.design
	, file = paste0(
		derivdir
		, 'stats/design.txt'
		)
	, sep = '\t'
	, row.names = F
	, col.names = F
	)
# the contrast matrix is created (rowwise)
txt.contrast <- rbind(
	c(1, 0, -1, 0, 0, 0)
	, c(0, 1, -1, 0, 0, 0)
	, c(1, -1, 0, 0, 0, 0)
	, c(-1, 0, 1, 0, 0, 0)
	, c(0, -1, 1, 0, 0, 0)
	, c(-1, 1, 0, 0, 0, 0)
	)
# the contrast matrix is written out to the stats folder in derivatives
write.table(
	txt.contrast
	, file = paste0(
		derivdir
		, 'stats/contrast.txt'
		)
	, sep = '\t'
	, row.names = F
	, col.names = F
	, quote = F
	)
# the ftest contrast is created (a single row)
txt.ftest <- rbind(
	c(1, 1, 0, 0, 0, 0)
	)
# the ftest contrast is written out to the stats folder in derivatives
write.table(
	txt.ftest
	, file = paste0(
		derivdir
		, 'stats/ftest.txt'
		)
	, sep = '\t'
	, row.names = F
	, col.names = F
	, quote = F
	)
