# preamble####

# environmental variables are cleared, and the console is erased
rm(list = ls())
cat('\014')

# libraries are loaded

# data import and management####
# the code directory is set as the study directory for this script
dir.r <- '/Users/coreyratcliffe/Documents/WD_code/rstats/221216_Proj-IS/'
dir.data <- '/Users/coreyratcliffe/Documents/WD_imaging/221216_Proj-IS/derivatives/'
setwd(dir.r)
source('00_functions.r')

# importing the demographics
ptcvars <- read.delim(
	'resources/participants.tsv'
	, dec = '.'
	, sep = '\t'
	, numerals = 'no.loss'
	)
ptcvars$sex <- factor(
	ptcvars$sex
	)
ptcvars$group <- factor(
	ptcvars$group
	, levels = c('HC', 'IGE', 'DRE')
	)
ptcvars_demos <- describeBy(
	data.frame(
		ptcvars$age
		, ptcvars$tpv
		)
	, ptcvars$group
	)
age_ftest <- summary(
	aov(
		ptcvars$age ~ ptcvars$group
		)
	)
age_post <- pairwise.t.test(
	ptcvars$age
	, ptcvars$group
	, p.adjust.method = 'none'
	)
tpv_ftest <- summary(
	aov(
		ptcvars$tpv ~ ptcvars$group
		)
	)
tpv_post <- pairwise.t.test(
	ptcvars$tpv
	, ptcvars$group
	, p.adjust.method = 'none'
	)
sex_ftest <- chisq.test(
	table(
		ptcvars$group
		, ptcvars$sex
		)
	)
sex_post_hcdre <- chisq.test(
	table(
		ptcvars$group[ptcvars$group != 'IGE']
		, ptcvars$sex[ptcvars$group != 'IGE']
		)
	)
sex_post_hcige <- chisq.test(
	table(
		ptcvars$group[ptcvars$group != 'DRE']
		, ptcvars$sex[ptcvars$group != 'DRE']
		)
	)
sex_post_dreige <- chisq.test(
	table(
		ptcvars$group[ptcvars$group != 'HC']
		, ptcvars$sex[ptcvars$group != 'HC']
		)
	)
ptcvars$age <- (ptcvars$age - mean(ptcvars$age)) / ptcvars$age
ptcvars$age <- (ptcvars$tpv - mean(ptcvars$tpv)) / ptcvars$tpv
# importing the metadata needed to organise the dice labels (i.e. the order in
# which the regions were captured)
opt.dicelabels <- read.delim(
	'resources/dice_labels.tsv'
	, dec = '.'
	, sep = '\t'
	, numerals = 'no.loss'
	, header = F
	)
# importing the metadata needed to add the correct roi labels to the dice scores
opt.diceregions <- read.delim(
	'resources/dice_regions.tsv'
	, dec = '.'
	, sep = '\t'
	, numerals = 'no.loss'
	)

# FreeSurfer####
# a vector of all the FreeSurfer measurement filenames is created
temp.files <- list.files(
	path = 'input/measurements_fs'
	, full.names = T
	)
# a list is created to contain the raw data
tab.fs_raw <- list()
# all of the aseg and cort files are read in
for (i in temp.files){
	j <- sub(
		'.*/(.*?)\\..*'
		, '\\1'
		, i
		)
	tab.fs_raw[[j]] <- read.delim(
		i
		, dec = '.'
		, sep = '\t'
		, numerals = 'no.loss'
		, row.names = 1
		)
	row.names(tab.fs_raw[[j]]) <- ptcvars$studyid
}
# the modality identifiers are extracted from the names of the input files
opt.mods <- unique(
	sub(
		'-.*'
		, ''
		, names(
			tab.fs_raw
			)
		)
	)
# the comparison identifiers are extracted from the names of the input files
opt.comps <- unique(
	sub(
		'^[^-]*-'
		, ''
		, names(
			tab.fs_raw
			)
		)
	)
# inconsistencies in column names are addressed
for (i in 1:length(tab.fs_raw)){
	# a temporary vector of column names is extracted
	temp.colnames <- colnames(tab.fs_raw[[i]])
	# all periods are replaced with underscores
	temp.colnames <- gsub(
		'\\.'
		, '_'
		, temp.colnames
		)
	# all instances of '_thickness' are removed
	temp.colnames <- gsub(
		'_thickness'
		, ''
		, temp.colnames
		)
	# all instances of '_volume' are removed
	temp.colnames <- gsub(
		'_volume'
		, ''
		, temp.colnames
		)
	# column names are reassigned based on the new format
	colnames(tab.fs_raw[[i]]) <- temp.colnames
	if (! grepl('dl', names(tab.fs_raw))[i]){
		if (grepl('aseg', names(tab.fs_raw))[i]){
		tab.fs_raw[[i]]$Corpus_Callosum <- rowSums(
			data.frame(
				tab.fs_raw[[i]]$CC_Posterior
				, tab.fs_raw[[i]]$CC_Mid_Posterior
				, tab.fs_raw[[i]]$CC_Central
				, tab.fs_raw[[i]]$CC_Mid_Anterior
				, tab.fs_raw[[i]]$CC_Anterior
				)
			)
		tab.fs_raw[[i]]$Left_Cerebellum <- rowSums(
			data.frame(
				tab.fs_raw[[i]]$Left_Cerebellum_Cortex
				, tab.fs_raw[[i]]$Left_Cerebellum_White_Matter
				)
			)
		tab.fs_raw[[i]]$Right_Cerebellum <- rowSums(
			data.frame(
				tab.fs_raw[[i]]$Right_Cerebellum_Cortex
				, tab.fs_raw[[i]]$Right_Cerebellum_White_Matter
				)
			)
		}
	}
}
colnames(tab.fs_raw$`dldir_fs-aseg_volume`)[c(6, 19)] <- c(
	'Left_Thalamus'
	, 'Right_Thalamus'
	)
colnames(tab.fs_raw$`dliso_fs-aseg_volume`)[c(6, 19)] <- c(
	'Left_Thalamus'
	, 'Right_Thalamus'
	)
colnames(tab.fs_raw$`dlsyn_fs-aseg_volume`)[c(6, 19)] <- c(
	'Left_Thalamus'
	, 'Right_Thalamus'
	)
# all of the common subcortical regions are extracted from the column names of
# the input data
opt.roiasegvol <- Reduce(
	intersect
	, list(
		colnames(
			tab.fs_raw$`aniso_fs-aseg_volume`
			)
		, colnames(
			tab.fs_raw$`aniso_fsc-aseg_volume`
			)
		, colnames(
			tab.fs_raw$`dldir_fs-aseg_volume`
			)
		)
	)
# all of the common cortical volume regions are extracted from the column names
# of the input data
opt.roicortvol <- Reduce(
	intersect
	, list(
		colnames(
			tab.fs_raw$`aniso_fs-cort_volume`
			)
		, colnames(
			tab.fs_raw$`aniso_fsc-cort_volume`
			)
		, colnames(
			tab.fs_raw$`dldir_fs-cort_volume`
			)
		)
	)
# all of the common cortical thickness regions are extracted from the column 
# names of the input data
opt.roicortthi <- Reduce(
	intersect
	, list(
		colnames(
			tab.fs_raw$`aniso_fs-cort_thickness`
			)
		, colnames(
			tab.fs_raw$`aniso_fsc-cort_thickness`
			)
		, colnames(
			tab.fs_raw$`dldir_fs-cort_thickness`
			)
		)
	)
# dataframes are trimmed to ensure consistent dimensions (and to remove extra
# columns, such as eTIV and SurfaceHoles
for (i in 1:length(tab.fs_raw)){
	if (grepl('aseg_volume', names(tab.fs_raw))[i]){
		tab.fs_raw[[i]] <- tab.fs_raw[[i]][, opt.roiasegvol]
	}else if (grepl('cort_volume', names(tab.fs_raw))[i]){
		tab.fs_raw[[i]] <- tab.fs_raw[[i]][, opt.roicortvol]
	}else if (grepl('cort_thickness', names(tab.fs_raw))[i]){
		tab.fs_raw[[i]] <- tab.fs_raw[[i]][, opt.roicortthi]
	}
}
# dataframes are sorted into separate lists, for comparison
for (i in opt.comps){
	temp.lname <- paste0(
		'tab.'
		, i
		)
	assign(
		temp.lname
		, list()
		)
	temp.list <- get(
		temp.lname
		)
	for (j in names(tab.fs_raw)){
		k <- 	sub(
		'-.*'
		, ''
		, j
		)
		if (grepl(i, j)){
			temp.list[[k]] <- tab.fs_raw[[j]]
		}
	}
	assign(
		temp.lname
		, temp.list
		)
}

# dice####
# a vector of all the dice filenames is created
temp.files <- list.files(
	path = 'input/measurements_dice'
	, full.names = T
	)
# the roi regions for the dice scores are made consistent with the FS regions
temp.vec <- unlist(opt.diceregions[2])
temp.vec <- gsub(
	'-'
	, '_'
	, temp.vec
	)
opt.diceregions <- temp.vec
# lists are created to contain the raw data
tab.dice_dsc <- list()
tab.dice_ovl <- list()
tab.dice_vol <- list()
# all of the overlap, volume, and dice files are read in
for (i in temp.files){
	j <- sub(
		'.*/(.*?)\\..*'
		, '\\1'
		, i
		)
	k <- 	sub(
		'-.*'
		, ''
		, j
		)
	if (grepl('-vol', j)){
			temp.list <- tab.dice_vol
	} else if (grepl('-ovl', j)){
			temp.list <- tab.dice_ovl
	} else if (grepl('-dsc', j)){
			temp.list <- tab.dice_dsc
	}
	temp.list[[k]] <- read.delim(
		i
		, dec = '.'
		, sep = '\t'
		, numerals = 'no.loss'
		, header = T
		)
	rownames(temp.list[[k]]) <- unlist(opt.dicelabels)
	temp.list[[k]] <- temp.list[[k]][order(
		as.numeric(
			rownames(
				temp.list[[k]]
				)
			)
		), ]
	rownames(temp.list[[k]]) <- opt.diceregions
	temp.list[[k]] <- temp.list[[k]][rownames(
		temp.list[[k]]
		) %in% c(
			opt.roiasegvol
			, opt.roicortvol
			), ]
	if (grepl('-vol', j)){
			tab.dice_vol <- temp.list
	} else if (grepl('-ovl', j)){
			tab.dice_ovl <- temp.list
	} else if (grepl('-dsc', j)){
			tab.dice_dsc <- temp.list
	}
}

# creation of index-label files

temp <- unlist(opt.dicelabels)
temp <- temp[order(
	as.numeric(
		temp
		)
)]

opt.index <- data.frame(
	temp
	, opt.diceregions
)

opt.index <- opt.index[
	opt.index$opt.diceregions %in% c(
		opt.roiasegvol
		, opt.roicortvol
		), ]

# temporary dsc computation
tab.dice_ovl$iso_fs <- tab.dice_vol$iso_fs
tab.dice_ovl <- tab.dice_ovl[names(tab.dice_vol)]
for (i in 1:length(tab.dice_ovl)){
	tab.dice_dsc[[i]] <- 2 * (tab.dice_ovl[[i]] / (tab.dice_vol[[i]] + tab.dice_vol$iso_fs))
}
names(tab.dice_dsc) <- opt.mods

# fsl####
# a vector of all the fsl data filenames is created
temp.files <- list.files(
	path = 'input/measurements_fsl'
	, full.names = T
	)
# lists are created to contain the raw data
tab.fsl_sig <- list()
tab.fsl_vol <- list()

for (i in temp.files){
	j <- sub(
		'.*/(.*?)\\..*'
		, '\\1'
		, i
		)
	k <- 	sub(
		'_.*'
		, ''
		, j
		)
	if (grepl('_vol', j)){
		tab.fsl_vol[[k]] <- read.delim(
			i
			, dec = '.'
			, sep = '\t'
			, numerals = 'no.loss'
			, header = T
			, row.names = 1
			)
	} else if (grepl('_sig', j)){
		tab.fsl_sig[[k]] <- t(
			read.delim(
				i
				, dec = '.'
				, sep = '\t'
				, numerals = 'no.loss'
				, header = T
				, row.names = 1
				)
			)
	}
}
for (i in 1:length(tab.fsl_sig)){
	row.names(tab.fsl_sig[[i]]) <- row.names(tab.fsl_vol[[i]])
	colnames(tab.fsl_vol[[i]]) <- ptcvars$studyid
}

save(
	ptcvars
	, tab.dice_dsc
	, opt.mods
	, opt.index
	, file = paste0(
		dir.r
		, 'input/dsc_data.rdata'
		)
	)

# all the relevant information is saved into an rdata file for easy future use
save(
	ptcvars
	, tab.aseg_volume
	, tab.cort_thickness
	, tab.cort_volume
	, opt.comps
	, opt.mods
	, opt.roiasegvol
	, opt.roicortthi
	, opt.roicortvol
	, opt.index
	, file = paste0(
		dir.r
		, 'input/fs_data.rdata'
		)
	)

# all the relevant information is saved into an rdata file for easy future use
save(
	ptcvars
	, tab.fsl_sig
	, tab.fsl_vol
	, file = paste0(
		dir.r
		, 'input/fsl_data.rdata'
		)
	)