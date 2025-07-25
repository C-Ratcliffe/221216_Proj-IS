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

# importing the data, and the image files
load(
	paste0(
		studydir
		, 'input/dsc_data.rdata'
		)
)
destrieux_cort <- readNifti(
'resources/destrieux_cort-dilate.nii.gz'
	)
destrieux_subcort <- readNifti(
'resources/destrieux_subcort.nii.gz'
	)

asegvec <- opt.index$temp[1:26]

descriptives <- matrix(
	NA
	, nrow = 3
	, ncol = 8
	, dimnames = list(
		x = c(
			'all'
			, 'sub'
			, 'cort'
			)
		, y = opt.mods
		)
	)

## The destrieux atlas is reparcellated to reflect the CC and Cerebellar parcellations used by DL+DiReCT####
destrieux_cort[destrieux_cort == 7 | destrieux_cort == 8] <- 104
destrieux_cort[destrieux_cort == 46 | destrieux_cort == 47] <- 117
destrieux_cort[destrieux_cort == 251 | destrieux_cort == 252 | destrieux_cort == 253 | destrieux_cort == 254 | destrieux_cort == 255] <- 130
destrieux_cort[! destrieux_cort %in% opt.index$temp | destrieux_cort < 1000 ] <- 0
destrieux_subcort[! destrieux_subcort %in% opt.index$temp] <- 0

## A for loop is used to change the intensity of the base atlas to reflect the dice scores of the different modalities####
for (i in opt.mods){
	dice_mat <- tab.dice_dsc[[i]]
	dice_means <- rowMeans(
		dice_mat
		)
	parc_ints <- cbind(
		opt.index[1]
		, dice_means
		)
	aseg_ints <- parc_ints[1:26, ]
	cort_ints <- parc_ints[27:174, ]
	base_atlas <- destrieux_cort
	for (j in 1:nrow(parc_ints)){
		base_atlas[base_atlas == parc_ints[j, 1]] <- parc_ints[j, 2]
	}
	base_subatlas <- destrieux_subcort
	for (j in 1:nrow(aseg_ints)){
		base_subatlas[base_subatlas == aseg_ints[j, 1]] <- aseg_ints[j, 2]
	}
	cortpath <- paste0(
		'output/cortdsc-'
		, i
		, '.nii.gz'
		)
	asegpath <- paste0(
		'output/asegdsc-'
		, i
		, '.nii.gz'
		)
	writeNifti(
		base_atlas
		, cortpath
		)
	writeNifti(
		base_subatlas
		, asegpath
		)
	descriptives[1, i] <- paste0(
		round(
			mean(
				parc_ints[,2]
				, na.rm = T
				)
			, 2
			)
		, ' ('
		, round(
			min(
				parc_ints[,2]
				, na.rm = T
				)
			, 2
			)
		, ' - '
		, round(
			max(
				parc_ints[,2]
				, na.rm = T
				)
			, 2
			)
		, ')'
		)
	descriptives[2, i] <- paste0(
		round(
			mean(
				aseg_ints[,2]
				, na.rm = T
				)
			, 2
			)
		, ' ('
		, round(
			min(
				aseg_ints[,2]
				, na.rm = T
				)
			, 2
			)
		, ' - '
		, round(
			max(
				aseg_ints[,2]
				, na.rm = T
				)
			, 2
			)
		, ')'
		)
	descriptives[3, i] <- paste0(
		round(
			mean(
				cort_ints[,2]
				, na.rm = T
				)
			, 2
			)
		, ' ('
		, round(
			min(
				cort_ints[,2]
				, na.rm = T
				)
			, 2
			)
		, ' - '
		, round(
			max(
				cort_ints[,2]
				, na.rm = T
				)
			, 2
			)
		, ')'
		)
}
# the descriptives table is written out as a tsv
write.table(
	descriptives
	, paste0(
		'output/dice-descriptives.tsv'
		)
	, quote = F
	, sep = '\t'
	)

# the dice overlaps are averaged for each modality, in each region (giving a 
# data frame of 174 by 8)
temp.data <- tab.dice_dsc
for (i in 1:length(temp.data)){
	temp.data[[i]] <- rowMeans(temp.data[[i]])
}
temp.data <- as.data.frame(temp.data)
temp.data$iso_fs <- NULL
# the modality/region averages are converted into a long table, for use with 
# ggplot
temp.data <- pivot_longer(
	temp.data
	, cols = everything()
	)
colours <- c(
	'aniso_fs' = '#816ed0'
	, 'aniso_fsc' = '#67ad4d'
	, 'dldirect_fs' = '#b868aa'
	, 'iso_fsc' = '#c88d2d'
	, 'res_fs' = '#4ea999'
	, 'res_fsc' = '#cc5560'
	, 'synth_fs' = '#a08149'
	)
plot.violin <- ggplot(
	temp.data
	, aes(
		x = name
		, y = value
		)
	)+
	geom_violin(
		trim = F
		, lwd = rel(0.5)
		, alpha = 0.8
		, aes(
			fill = name
			, colour = name
			)
		)+
	geom_jitter(
		shape = 20
		, width = 0.05
		, colour = 'grey'
		, alpha = 0.8
		)+
	stat_summary(
		fun=mean
		, geom = 'point'
		, position = position_dodge(0.9)
		, shape = 5
		, size = 3
		, colour = 'black'
		)+
	coord_flip(
		)+
	scale_fill_manual(
		values = colours
		)+
	scale_colour_manual(
		values = colours
		)+
	scale_y_continuous(
		limits = c(0.2, 1)
		, breaks = c(0.2, 0.6, 1)
		)+
	theme(
		text = element_text(
			family='roboto light'
			, size = 12
			, colour = 'black'
			)
		, legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major.x = element_line(
			colour = 'grey'
			, linewidth = 0.25
			)
		, panel.grid.major.y = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, plot.margin = unit(
			c(0, 0, 0, 0)
			, "mm"
			)
		, title = element_blank()
		, axis.text.y = element_blank()
		, axis.title.x = element_blank()
		, axis.text.x = element_text(
			colour = 'black'
			, size = 12
			)
		, axis.title.y = element_blank()
		, axis.ticks = element_blank()
	)
fname.violin <- paste0(
	'output/dice-violin.png'
	)
ggsave(
	plot = plot.violin
	, device = 'png'
	, height = 3500
	, width = 2000
	, units = 'px'
	, filename = fname.violin
	, dpi = 300
	)
