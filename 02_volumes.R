# preamble####

# environmental variables are cleared, and the console is erased
rm(list = ls())
cat("\014")

# libraries are loaded
library('RNifti')
library('miscTools')
library('ggplot2')
library('tidyr')
library('psych')

# data import and management####
# the code directory is set as the study directory for this script
dir.r <- '/Users/coreyratcliffe/Documents/WD_code/rstats/221216_Proj-IS/'
dir.data <- '/Users/coreyratcliffe/Documents/WD_imaging/221216_Proj-IS/derivatives/'
setwd(dir.r)
source("00_functions.r")

# importing the data, and the image files
load(
	paste0(
		dir.r
		, 'input/fs_data.rdata'
		)
)
dir.create(
	paste0(dir.r, 'output/iccs')
	, showWarnings = F
	, recursive = T
	)
destrieux_cort <- readNifti(
'resources/destrieux_cort-dilate.nii.gz'
	)
destrieux_subcort <- readNifti(
'resources/destrieux_subcort.nii.gz'
	)
asegvec <- opt.index$temp[1:26]
destrieux_cort[! destrieux_cort %in% opt.index$temp | destrieux_cort < 1000 ] <- 0
destrieux_subcort[! destrieux_subcort %in% opt.index$temp] <- 0

# ICCs
# The ICC3 score is used, as the raters (i.e. ISO-FS and other) are fixed and 
# won't generalise
tab.icc <- list()
for (i in c('aseg_volume', 'cort_thickness', 'cort_volume')){
	j <- get(
		paste0(
			'tab.'
			, i
			)
		)
	tab.icc[[i]] <- t(
	data.frame(
		lapply(
			j
			, colMeans
			)
		)
	)
	for (k in 1:length(j)){
		for (l in 1:length(j[[k]])){
			temp <- data.frame(j[[k]][[l]], j$iso_fs[[l]])
			temp.icc <- ICC(
				temp
				, lmer = T
				)
			tab.icc[[i]][k, l] <- temp.icc[[1]][3,2]
		}
	}
	tab.icc[[i]] <- rowMeans(
		tab.icc[[i]]
		)
}
tab.icc <- t(
	data.frame(
		tab.icc
		)
	)

# metric correlation/scatterplots####
plots <- list()
for (i in c('aseg_volume', 'cort_thickness', 'cort_volume')){
	j <- get(
		paste0(
			'tab.'
			, i
			)
		)
	k <- data.frame(
		lapply(
			j
			, colMeans
			)
		)
	lim_min <- floor(
		min(
			k
			, na.rm = T
			)
		)
	lim_max <- ceiling(
		max(
			k
			, na.rm = T
			)
		)
	temp.data <- pivot_longer(
		k
		, cols = -'iso_fs'
		, names_to = 'variable'
		, values_to = 'value'
	)
	ind.body <- ! temp.data$variable == 'dliso_fs' & ! temp.data$variable == 'dlsyn_fs'
	ind.supp <- temp.data$variable == 'dldir_fs' | temp.data$variable == 'dliso_fs' | temp.data$variable == 'dlsyn_fs'
	colours.body <- c(
		'aniso_fs' = '#816ed0'
		, 'aniso_fsc' = '#67ad4d'
		, 'dldir_fs' = '#b868aa'
		, 'iso_fsc' = '#c88d2d'
		, 'res_fs' = '#4ea999'
		, 'res_fsc' = '#cc5560'
		, 'synth_fs' = '#a08149'
		)
	colours.supp <- c(
		'dldir_fs' = '#b868aa'
		, 'dliso_fs' = '#7a5bac'
		, 'dlsyn_fs' = '#d17ca0'
		)
	fname.body <- paste0(
		'output/iccs/'
		, i
		, '_body.png'
		)
	fname.supp <- paste0(
		'output/iccs/'
		, i
		, '_supp.png'
		)
	height.body <- 2480
	height.supp <- 1063
	for (j in c('body', 'supp')){
		temp.ind <- get(
			paste0(
				'ind.'
				, j
				)
			)
		temp.colours <- get(
			paste0(
				'colours.'
				, j
				)
			)
		temp.fname <- get(
			paste0(
				'fname.'
				, j
				)
			)
		temp.height <- get(
			paste0(
				'height.'
				, j
				)
			)
		temp.trunc <- temp.data[temp.ind, ]
		plots[[i]] <- ggplot(
		temp.trunc
		, aes(
			x = iso_fs
			, y = value
			, colour = variable
			)
		)+
		geom_abline(
			linewidth = 0.25
			, colour = 'darkgrey'
			)+
	  geom_point(
	  	alpha = 0.6
	  	)+
		scale_colour_manual(
			values = temp.colours
			)+
		scale_x_continuous(
			limits = c(
				lim_min
				, lim_max
				)
			)+
		scale_y_continuous(
			, limits = c(
				lim_min
				, lim_max
				)
			)+
	  theme_minimal(
	  	)+
		theme(
			legend.position = 'none'
			, panel.grid.minor = element_blank()
			, panel.grid.major = element_blank()
			, panel.background = element_blank()
			, plot.background = element_blank()
			, plot.tag = element_blank()
			, plot.title = element_blank()
			, axis.text.y = element_text(
				angle = 90
				, hjust = 0.5
				, size = 6
				, colour = 'black'
				, family = 'Roboto Light'
				)
			, axis.text.x = element_text(
				size = 10
				, colour = 'black'
				, family = 'Roboto Light'
				)
			, axis.title.y = element_blank()
			, axis.title.x = element_blank()
			, axis.ticks = element_line(
				colour = 'black'
				)
			, axis.line = element_line(
				colour = 'black'
				)
			)+
	  facet_wrap(
	  	~ variable
	  	, scales = 'fixed'
	  	, ncol = 1
	  	)+
		theme(
			strip.text = element_blank()
			, strip.background = element_blank()
			)
	ggsave(
		plot = plots[[i]]
		, device = 'png'
		, height = temp.height
		, width = 728
		, units = 'px'
		, filename = temp.fname
		)
	}
}

# normalisation####
for (i in c(1:5, 7:10, 6)){
	for (j in 1:length(tab.aseg_volume[[i]])){
		k <- unlist(tab.aseg_volume[[i]][j])
		l <- unlist(tab.aseg_volume$iso_fs[j])
		k <- (k - mean(l)) / sd(l)
		tab.aseg_volume[[i]][j] <- k
	}
	tab.aseg_volume[[i]] <- colMeans(tab.aseg_volume[[i]])
	for (j in 1:length(tab.cort_thickness[[i]])){
		k <- unlist(tab.cort_thickness[[i]][j])
		l <- unlist(tab.cort_thickness$iso_fs[j])
		k <- (k - mean(l)) / sd(l)
		tab.cort_thickness[[i]][j] <- k
	}
	tab.cort_thickness[[i]] <- colMeans(tab.cort_thickness[[i]])
	for (j in 1:length(tab.cort_volume[[i]])){
		k <- unlist(tab.cort_volume[[i]][j])
		l <- unlist(tab.cort_volume$iso_fs[j])
		k <- (k - mean(l)) / sd(l)
		tab.cort_volume[[i]][j] <- k
	}
	tab.cort_volume[[i]] <- colMeans(tab.cort_volume[[i]])
}
tab.mask <- list()
tab.violin <- list()

tab.aseg_volume$iso_fs <- NULL
tab.aseg_volume <- as.data.frame(tab.aseg_volume)
tab.violin$asegvol <- pivot_longer(
	tab.aseg_volume
	, cols = everything()
	)
tab.mask$asegvol <- tab.aseg_volume

tab.cort_thickness$iso_fs <- NULL
tab.cort_thickness <- as.data.frame(tab.cort_thickness)
tab.violin$cortthi <- pivot_longer(
	tab.cort_thickness
	, cols = everything()
	)
tab.mask$cortthi <- tab.cort_thickness

tab.cort_volume$iso_fs <- NULL
tab.cort_volume <- as.data.frame(tab.cort_volume)
tab.violin$cortvol <- pivot_longer(
	tab.cort_volume
	, cols = everything()
	)
tab.mask$cortvol <- tab.cort_volume

tab.violin$vol <- rbind(tab.violin$asegvol, tab.violin$cortvol)

# creating volume mask images####
for (i in opt.mods[-6]){
	asegvol_ints <- cbind(
		opt.index[1:26, 1]
		, tab.mask$asegvol[i]
		)
	base_asegvol <- destrieux_subcort
	for (j in 1:nrow(asegvol_ints)){
		base_asegvol[base_asegvol == asegvol_ints[j, 1]] <- asegvol_ints[j, 2]
	}
	avpath <- paste0(
		'output/asegvol-'
		, i
		, '.nii.gz'
		)
	writeNifti(
		base_asegvol
		, avpath
		)
	cortthi_ints <- cbind(
		opt.index[27:174, 1]
		, tab.mask$cortthi[i]
		)
	base_cortthi <- destrieux_cort
	for (j in 1:nrow(cortthi_ints)){
		base_cortthi[base_cortthi == cortthi_ints[j, 1]] <- cortthi_ints[j, 2]
	}
	ctpath <- paste0(
		'output/cortthi-'
		, i
		, '.nii.gz'
		)
	writeNifti(
		base_cortthi
		, ctpath
		)
	cortvol_ints <- cbind(
		opt.index[27:174, 1]
		, tab.mask$cortvol[i]
		)
	base_cortvol <- destrieux_cort
	for (j in 1:nrow(cortvol_ints)){
		base_cortvol[base_cortvol == cortvol_ints[j, 1]] <- cortvol_ints[j, 2]
	}
	cvpath <- paste0(
		'output/cortvol-'
		, i
		, '.nii.gz'
		)
	writeNifti(
		base_cortvol
		, cvpath
		)
}

# violin plots####
for (i in 1:length(tab.violin)){
	temp.data <- tab.violin[[i]]
	temp.data$name <- factor(
		temp.data$name
		, levels = rev(
			levels(
				factor(
					temp.data$name
					)
				)
			)
		)
	ind.body <- ! temp.data$name == 'dliso_fs' & ! temp.data$name == 'dlsyn_fs'
	ind.supp <- temp.data$name == 'dldir_fs' | temp.data$name == 'dliso_fs' | temp.data$name == 'dlsyn_fs'
	colours.body <- c(
		'aniso_fs' = '#816ed0'
		, 'aniso_fsc' = '#67ad4d'
		, 'dldir_fs' = '#b868aa'
		, 'iso_fsc' = '#c88d2d'
		, 'res_fs' = '#4ea999'
		, 'res_fsc' = '#cc5560'
		, 'synth_fs' = '#a08149'
		)
	colours.supp <- c(
		'dldir_fs' = '#b868aa'
		, 'dliso_fs' = '#7a5bac'
		, 'dlsyn_fs' = '#d17ca0'
		)
	fname.body <- paste0(
		'output/violin-'
		, names(tab.violin)[i]
		, '_body.png'
		)
	fname.supp <- paste0(
		'output/violin-'
		, names(tab.violin)[i]
		, '_supp.png'
		)
	height.body <- 2480
	height.supp <- 1063
	for (j in c('body', 'supp')){
		temp.ind <- get(
			paste0(
				'ind.'
				, j
				)
			)
		temp.colours <- get(
			paste0(
				'colours.'
				, j
				)
			)
		temp.fname <- get(
			paste0(
				'fname.'
				, j
				)
			)
		temp.height <- get(
			paste0(
				'height.'
				, j
				)
			)
		temp.trunc <- temp.data[temp.ind, ]
		if (names(tab.violin)[i] == 'cortthi'){
			limits.y <- c(-8, 8)
			breaks.y <- c(-8, 0, 8)
		} else {
			limits.y <- c(-4, 4)
			breaks.y <- c(-4, 0, 4)
		}
		plot.violin <- ggplot(
			temp.trunc
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
				values = temp.colours
				)+
			scale_colour_manual(
				values = temp.colours
				)+
			scale_y_continuous(
				limits = limits.y
				, breaks = breaks.y
				)+
			theme(
				text = element_text(
					family='roboto light'
					, size = 10
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
					, size = 10
					)
				, axis.title.y = element_blank()
				, axis.ticks = element_blank()
			)
		ggsave(
			plot = plot.violin
			, device = 'png'
			, height = temp.height
			, width = 1420
			, units = 'px'
			, filename = temp.fname
			, dpi = 300
			)
	}
}
