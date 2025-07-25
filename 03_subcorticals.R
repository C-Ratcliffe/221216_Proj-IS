# preamble####

# environmental variables are cleared, and the console is erased
rm(list = ls())
cat("\014")

# libraries are loaded
library('RNifti')
library('miscTools')
library('ggplot2')
library('ggpubr')
library('tidyr')
library('psych')

# data import and management####
# the code directory is set as the study directory for this script
studydir <- '/Users/coreyratcliffe/Documents/WD_code/rstats/221216_Proj-IS/'
derivdir <- '/Users/coreyratcliffe/Documents/WD_imaging/221216_Proj-IS/derivatives/'
setwd(studydir)
source("00_functions.r")

# importing the data
load(
	paste0(
		studydir
		, 'input/fsl_data.rdata'
		)
)
dir.create(
	paste0(studydir, 'output/volsigs')
	, showWarnings = F
	, recursive = T
	)

# defining data structures and testing univariable relationships
list.ptcdemos <- list()
list.volglm <- list()
list.volnorm <- list()
list.volhomo <- list()
list.volsig <- list()
list.volsig$f <- matrix(
	nrow = 4
	, ncol = 14
	)
list.volsig$hc_ige <- matrix(
	nrow = 4
	, ncol = 14
	)
list.volsig$hc_dre <- matrix(
	nrow = 4
	, ncol = 14
	)
list.volsig$dre_ige <- matrix(
	nrow = 4
	, ncol = 14
	)
list.ptcdemos$age <- glm(
	age ~ group
	, data = ptcvars
	)
list.ptcdemos$age <- summary(
	list.ptcdemos$age
	)
list.ptcdemos$tpv <- glm(
	tpv ~ group
	, data = ptcvars
	)
list.ptcdemos$tpv <- summary(
	list.ptcdemos$tpv
	)
list.ptcdemos$sex <- chisq.test(
	table(
		ptcvars$group
		, ptcvars$sex
		)
	)

# a for loop computes a glm for all of the subcortical volumes####
for (i in 1:length(tab.fsl_vol)){
	for (j in 1:nrow(tab.fsl_vol[[i]])){
		cellname <- paste(
			names(
				tab.fsl_vol
				)[i]
			, rownames(
				tab.fsl_vol[[i]]
				)[j]
			, sep = '_'
			)
		temp.vol <- t(
			tab.fsl_vol[[i]][j, ]
			)
		temp.aov <- aov(
			temp.vol ~ ptcvars$group + ptcvars$age + ptcvars$sex + ptcvars$tpv
			)
		list.volnorm[[cellname]] <- shapiro.test(
			resid(
				temp.aov
				)
			)
		list.volhomo[[cellname]] <- leveneTest(
			c(
				temp.vol
				)
			, ptcvars$group
			)
		temp.df <- data.frame(
			temp.vol
			, ptcvars$group
			)
		colnames(temp.df) <- c('vol', 'group')
		list.volglm[[cellname]] <- kruskal.test(
			vol ~ group
			, data = temp.df
			)
		list.volsig$f[i,j] <- as.numeric(
			list.volglm[[cellname]][[3]]
			)
		temp.dftrunc <- temp.df[temp.df$group != 'IGE', ] 
		temp.model <- kruskal.test(
			vol ~ group
			, data = temp.dftrunc
			)
		list.volsig$hc_dre[i,j] <- as.numeric(
			temp.model[[3]]
			)
		temp.dftrunc <- temp.df[temp.df$group != 'DRE', ]
		temp.model <- kruskal.test(
			vol ~ group
			, data = temp.dftrunc
			)
		list.volsig$hc_ige[i,j] <- as.numeric(
			temp.model[[3]]
			)
		temp.dftrunc <- temp.df[temp.df$group != 'HC', ]
		temp.model <- kruskal.test(
			vol ~ group
			, data = temp.dftrunc
			)
		list.volsig$dre_ige[i,j] <- as.numeric(
			temp.model[[3]]
		)
	}
}

for (i in 1:length(list.volsig)){
	colnames(list.volsig[[i]]) <- rownames(
		tab.fsl_vol[[1]]
		)
	rownames(list.volsig[[i]]) <- names(
		tab.fsl_vol
		)
	write.table(
		list.volsig[[i]]
		, paste0(
			'output/volsigs/'
			, names(list.volsig)[i]
			, '.tsv'
			)
		, quote = F
		, sep = '\t'
		)
}

rm(
	cellname
	, i
	, j
	, temp.aov
	, temp.vol
	)

#save(list_glm, mat_glmsig, file = "subcort-volumes_fs.rdata")
