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
# to collapse factor levels (i.e. DRE + IGE = pwE)
library('forcats')
# to allow the use of the leveneTest command
library('car')

# data import and management####
# the code directory is set as the study directory for this script
dir.r <- '/Users/coreyratcliffe/Documents/WD_code/rstats/221216_Proj-IS/'
dir.data <- '/Users/coreyratcliffe/Documents/WD_imaging/221216_Proj-IS/derivatives/'
setwd(dir.r)
source("00_functions.r")

# importing the data
load(
	paste0(
		dir.r
		, 'input/fsl_data.rdata'
		)
)
dir.create(
	paste0(dir.r, 'output/volsigs')
	, showWarnings = F
	, recursive = T
	)

#subgroups####
# defining data structures and testing univariable relationships
list.ftest.ptcdemos <- list()
list.ftest.volglm <- list()
list.ftest.volnorm <- list()
list.ftest.volhomo <- list()
list.ftest.volsig <- list()
list.ftest.volsig$f <- matrix(
	nrow = 4
	, ncol = 14
	)
list.ftest.volsig$hc_ige <- matrix(
	nrow = 4
	, ncol = 14
	)
list.ftest.volsig$hc_dre <- matrix(
	nrow = 4
	, ncol = 14
	)
list.ftest.volsig$dre_ige <- matrix(
	nrow = 4
	, ncol = 14
	)
list.ftest.ptcdemos$age <- glm(
	age ~ group
	, data = ptcvars
	)
list.ftest.ptcdemos$age <- summary(
	list.ftest.ptcdemos$age
	)
list.ftest.ptcdemos$tpv <- glm(
	tpv ~ group
	, data = ptcvars
	)
list.ftest.ptcdemos$tpv <- summary(
	list.ftest.ptcdemos$tpv
	)
list.ftest.ptcdemos$sex <- chisq.test(
	table(
		ptcvars$group
		, ptcvars$sex
		)
	)

# a for loop computes a glm for all of the subcortical volumes
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
		list.ftest.volnorm[[cellname]] <- shapiro.test(
			resid(
				temp.aov
				)
			)
		list.ftest.volhomo[[cellname]] <- leveneTest(
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
		list.ftest.volglm[[cellname]] <- kruskal.test(
			vol ~ group
			, data = temp.df
			)
		list.ftest.volsig$f[i,j] <- as.numeric(
			list.ftest.volglm[[cellname]][[3]]
			)
		temp.dftrunc <- temp.df[temp.df$group != 'IGE', ] 
		temp.model <- kruskal.test(
			vol ~ group
			, data = temp.dftrunc
			)
		list.ftest.volsig$hc_dre[i,j] <- as.numeric(
			temp.model[[3]]
			)
		temp.dftrunc <- temp.df[temp.df$group != 'DRE', ]
		temp.model <- kruskal.test(
			vol ~ group
			, data = temp.dftrunc
			)
		list.ftest.volsig$hc_ige[i,j] <- as.numeric(
			temp.model[[3]]
			)
		temp.dftrunc <- temp.df[temp.df$group != 'HC', ]
		temp.model <- kruskal.test(
			vol ~ group
			, data = temp.dftrunc
			)
		list.ftest.volsig$dre_ige[i,j] <- as.numeric(
			temp.model[[3]]
		)
	}
}

for (i in 1:length(list.ftest.volsig)){
	colnames(list.ftest.volsig[[i]]) <- rownames(
		tab.fsl_vol[[1]]
		)
	rownames(list.ftest.volsig[[i]]) <- names(
		tab.fsl_vol
		)
	write.table(
		list.ftest.volsig[[i]]
		, paste0(
			'output/volsigs/'
			, names(list.ftest.volsig)[i]
			, '.tsv'
			)
		, quote = F
		, sep = '\t'
		)
}

#patients vs controls####
# defining data structures and testing univariable relationships
ptcvars$group <- fct_collapse(
	ptcvars$group
	, pwE = c('DRE', 'IGE')
	)
list.ttest.ptcdemos <- list()
list.ttest.volglm <- list()
list.ttest.volnorm <- list()
list.ttest.volhomo <- list()
list.ttest.volsig <- list()
list.ttest.volsig$pwe_hc <- matrix(
	nrow = 4
	, ncol = 14
	)
list.ttest.ptcdemos$age <- glm(
	age ~ group
	, data = ptcvars
	)
list.ttest.ptcdemos$age <- summary(
	list.ttest.ptcdemos$age
	)
list.ttest.ptcdemos$tpv <- glm(
	tpv ~ group
	, data = ptcvars
	)
list.ttest.ptcdemos$tpv <- summary(
	list.ttest.ptcdemos$tpv
	)
list.ttest.ptcdemos$sex <- chisq.test(
	table(
		ptcvars$group
		, ptcvars$sex
		)
	)

# a for loop computes a glm for all of the subcortical volumes
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
		list.ttest.volnorm[[cellname]] <- shapiro.test(
			resid(
				temp.aov
				)
			)
		list.ttest.volhomo[[cellname]] <- leveneTest(
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
		list.ttest.volglm[[cellname]] <- kruskal.test(
			vol ~ group
			, data = temp.df
			)
		list.ttest.volsig$pwe_hc[i,j] <- as.numeric(
			list.ttest.volglm[[cellname]][[3]]
			)
	}
}

for (i in 1:length(list.ttest.volsig)){
	colnames(list.ttest.volsig[[i]]) <- rownames(
		tab.fsl_vol[[1]]
		)
	rownames(list.ttest.volsig[[i]]) <- names(
		tab.fsl_vol
		)
	write.table(
		list.ttest.volsig[[i]]
		, paste0(
			'output/volsigs/'
			, names(list.ttest.volsig)[i]
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
