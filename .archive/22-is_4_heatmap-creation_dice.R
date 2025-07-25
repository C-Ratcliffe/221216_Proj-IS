rm(list = ls())
cat("\014")
source("22-is_functions.r")
library("RNifti")
library("miscTools")

region_labels <- read.delim('resources/dice_regions.csv', sep = ",")
destrieux_base <- readNifti("resources/destrieux_cort-dilate.nii.gz")
destrieux_subcort <- readNifti("resources/destrieux_subcort.nii.gz")

## The data is imported and the names/indices are extracted####
folder.in <- "measurements_dice"
project <- "is"
opt.rois <- 179

names.file.list <- list.files(path=folder.in, full.names = T)
names.meas <-  gsub(".*[/](.*)[.]csv", "\\1", names.file.list[1:length(names.file.list)])
raw_meas <- lapply(names.file.list, read.delim, header = T, dec = ".", numerals = "no.loss", sep = " ")

for (i in 1:length(raw_meas)){
	row.names(raw_meas[[i]]) <- region_labels$ints
	raw_meas[[i]] <- raw_meas[[i]][, c(FALSE, TRUE, FALSE)]
}

names(raw_meas) <- names.meas

asegvec <-  c(10, 11, 12, 13, 16, 17, 18, 26, 49, 50, 51, 52, 53, 54, 58)
blankmat <- matrix(NA, nrow = 3, ncol = 2, dimnames = list(x = c('all', 'sub', 'cort'), y = c('mean', 'max')))

## The destrieux atlas is reparcellated to reflect the CC and Cerebellar parcellations used by DL+DiReCT####
destrieux_base[destrieux_base == 7] <- 104
destrieux_base[destrieux_base == 8] <- 104
destrieux_base[destrieux_base == 46] <- 117
destrieux_base[destrieux_base == 47] <- 117
destrieux_base[destrieux_base == 251] <- 130
destrieux_base[destrieux_base == 252] <- 130
destrieux_base[destrieux_base == 253] <- 130
destrieux_base[destrieux_base == 254] <- 130
destrieux_base[destrieux_base == 255] <- 130

## A for loop is used to change the intensity of the base atlas to reflect the dice scores of the different modalities####
for (modality in c('aniso', 'res', 'dldirect', 'synthsr')){
	rm_ind <- paste(modality, '-ovl', sep = '')
	dice_mat <- (2*(as.matrix(raw_meas[[rm_ind]])))/(as.matrix(raw_meas[[rm_ind]])+as.matrix(raw_meas$'iso-vol'))
	dice_means <- rowMeans(dice_mat)
	parc_ints <- cbind(region_labels[1], dice_means)
	aseg_ints <- parc_ints[1:31, ]
	cort_ints <- parc_ints[31:178, ]
	base_atlas <- destrieux_base
	for (i in 1:nrow(parc_ints)){
		base_atlas[base_atlas == parc_ints[i, 1]] <- parc_ints[i, 2]
	}
	base_atlas[base_atlas < min(parc_ints[,2], na.rm = T) | base_atlas > max(parc_ints[,2], na.rm = T)] <- 0
	base_subatlas <- destrieux_subcort
	for (i in 1:nrow(aseg_ints)){
		base_subatlas[base_subatlas == aseg_ints[i,1]] <- aseg_ints[i,2]
	}
	base_subatlas[base_subatlas < min(aseg_ints[,2], na.rm = T) | base_subatlas > max(aseg_ints[,2], na.rm = T)] <- 0
	cortpath_r <- paste('resources/', modality, '-cort_dice.nii.gz', sep = '')
	subpath_r <- paste('resources/', modality, '-aseg_dice.nii.gz', sep = '')
	cortpath_si <- paste('C:/Users/coreyar/Windows_Programs/Surf_Ice/display_vols/221216_Proj-IS/', modality, '-cort_dice.nii.gz', sep = '')
	subpath_si <- paste('C:/Users/coreyar/Windows_Programs/Surf_Ice/display_vols/221216_Proj-IS/', modality, '-aseg_dice.nii.gz', sep = '')
	writeNifti(base_atlas, cortpath_r)
	writeNifti(base_atlas, cortpath_si)
	writeNifti(base_subatlas, subpath_r)
	writeNifti(base_subatlas, subpath_si)
	dicedesc <- blankmat
	dicedesc[1,1] <- mean(parc_ints[,2], na.rm = T)
	dicedesc[1,2] <- max(parc_ints[,2], na.rm = T)
	dicedesc[2,1] <- mean(aseg_ints[,2], na.rm = T)
	dicedesc[2,2] <- max(aseg_ints[,2], na.rm = T)
	dicedesc[3,1] <- mean(cort_ints[,2], na.rm = T)
	dicedesc[3,2] <- max(cort_ints[,2], na.rm = T)
	assign(paste('dicedesc_', modality, sep = ''), dicedesc)
}
writeNifti(destrieux_base, 'C:/Users/coreyar/Windows_Programs/Surf_Ice/display_vols/221216_Proj-IS/iso-cort_dice.nii.gz')
writeNifti(destrieux_subcort, 'C:/Users/coreyar/Windows_Programs/Surf_Ice/display_vols/221216_Proj-IS/iso-aseg_dice.nii.gz')
