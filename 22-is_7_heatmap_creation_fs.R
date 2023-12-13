rm(list = ls())
cat("\014")
source("22-is_functions.r")
library("RNifti")
library("miscTools")
load("metrics_is.rdata")

destrieux_base <- readNifti("resources/destrieux_cort-dilate.nii")

vol_an <- c(z_avg[['an_vol_sub']], z_avg[['an_vol']])
vol_dl <- c(z_avg[['dl_vol_sub']], z_avg[['dl_vol']])
vol_res <- c(z_avg[['res_vol_sub']], z_avg[['res_vol']])
vol_ssr <- c(z_avg[['ssr_vol_sub']], z_avg[['ssr_vol']])
thick_an <- z_avg[['an_thick']]
thick_dl <- z_avg[['dl_thick']]
thick_res <- z_avg[['res_thick']]
thick_ssr <- z_avg[['ssr_thick']]

destrieux_base[destrieux_base == 7] <- 104
destrieux_base[destrieux_base == 8] <- 104
destrieux_base[destrieux_base == 46] <- 117
destrieux_base[destrieux_base == 47] <- 117
destrieux_base[destrieux_base == 251] <- 130
destrieux_base[destrieux_base == 252] <- 130
destrieux_base[destrieux_base == 253] <- 130
destrieux_base[destrieux_base == 254] <- 130
destrieux_base[destrieux_base == 255] <- 130

cortical_labels <- region_labels[31:178,]
subcortical_labels <- region_labels[1:30,]

for (i in c('an', 'dl', 'res', 'ssr')){
	for (j in c('vol', 'thick')){
		base_atlas <- destrieux_base
		inmetric <- paste(j, i, sep = '_')
		outfile_rdir <- paste('resources/', i, '_', j, '-z.nii.gz', sep = '')
		outfile <- paste('F:/Windows_Programs/Surf_Ice/display_vols/22-is/', i, '_', j, '-z.nii.gz', sep = '')
		if (j == 'vol') {
			parc_ints <- cbind(region_labels[1], eval(parse(text = inmetric)))
		} else if (j == 'thick') {
			parc_ints <- cbind(cortical_labels[1], eval(parse(text = inmetric)))
		} else {
			print("Error")
		}
		for (k in 1:nrow(parc_ints)){
			base_atlas[base_atlas == parc_ints[k,1]] <- parc_ints[k,2]
		}
		base_atlas[base_atlas < min(parc_ints[,2], na.rm = T) | base_atlas > max(parc_ints[,2], na.rm = T)] <- 0
		writeNifti(base_atlas, outfile)
		#writeNifti(base_atlas, outfile_rdir)
	}
}
