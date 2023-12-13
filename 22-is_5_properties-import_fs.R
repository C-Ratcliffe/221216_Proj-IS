rm(list = ls())
cat('\014')
source('22-is_functions.R')

#The data is imported and the names/indices are extracted####

folder.in <- "measurements_is"
project <- "is"
opt.rois <- 148

names.file.list <- list.files(path=folder.in, full.names = T)
names.methods <- gsub(paste(".*", project, "[_](.*)[_].*[_].*[.].*", sep=""), "\\1", names.file.list[1:length(names.file.list)])
names.hemi <-gsub(paste(".*", project, "[_].*[_](.*)[_].*[.].*", sep=""), "\\1", names.file.list[1:length(names.file.list)])
names.features <- gsub(paste(".*", project, "[_].*[_].*[_](.*)[.].*", sep=""), "\\1", names.file.list[1:length(names.file.list)])
raw_meas <- lapply(names.file.list, read.delim, header = T, dec = ".", numerals = "no.loss", sep = ",")
region_labels <- read.delim('resources/vol_regions.csv', sep = ',')

#The aseg parcellations are matched####

names(raw_meas) <- paste(names.methods, names.features, sep = '_')
raw_meas[["fsdlseg-aseg_volume"]] <- raw_meas[["fsdlseg-aseg_volume"]][,-30]
aseg_inds <- c(51, 1, 2, 18, 3, 5, 6, 7, 8, 12, 13, 15, 16, 52, 19, 20, 32, 21, 23, 24, 25, 26, 27, 28, 29, 30, 11, 9, 10, 41)

for (i in c('fsraw', 'fsaniso', 'fssynthsr', 'fsdldirect')){
	aseg_vols <- raw_meas[names.methods == paste(i, '-aseg', sep = '')][[1]]
	aseg_vols[,3] <- aseg_vols[,3] + aseg_vols[,4]
	aseg_vols[,21] <- aseg_vols[,21] + aseg_vols[22]
	aseg_vols[,41] <- aseg_vols[,41] + aseg_vols[42] + aseg_vols[43] + aseg_vols[44] + aseg_vols[45]
	aseg_vols <- aseg_vols[,aseg_inds]
	raw_meas[names.methods == paste(i, '-aseg', sep = '')][[1]] <- aseg_vols
}

#A for loop is used to extract the raw and synthesised freesurfer metrics####

for (i in c('fsraw', 'fsaniso', 'fssynthsr', 'fsdldirect', 'fsdlseg')){
	j <- paste(i, '-da', sep = '')
	k <- paste(i, '-aseg', sep = '')
	meas_fsint_cort <- raw_meas[names.methods == j]
	meas_fsint_subcort <- raw_meas[names.methods == k]
	assign(paste('meas_', i, sep = ''), list('thickness' = meas_fsint_cort[[1]]
		, 'volume' = cbind(meas_fsint_subcort[[1]], meas_fsint_cort[[3]])
	))
}

meas_fsres <- meas_fsdldirect
meas_fsdldirect <- meas_fsdlseg
meas <- c(meas_fsraw, meas_fsaniso, meas_fsdldirect, meas_fsres, meas_fssynthsr)
names(meas) <- c('raw_thick', 'raw_vol', 'an_thick', 'an_vol', 'dl_thick', 'dl_vol', 'res_thick', 'res_vol', 'ssr_thick', 'ssr_vol')

for (i in seq(to = length(meas), by = 2, from = 2)){
	j <- (i/2)+10
	meas[[paste(names(meas)[i], 'sub',sep = '_')]] <- meas[[i]][1:30]
	meas[[i]] <- meas[[i]][31:178]
}

meas <- meas[names(meas)[c(1, 2, 11, 3, 4, 12, 5, 6, 13, 7, 8, 14, 9, 10, 15)]]

#Intermediary files are removed and the rawdata are saved####

rm(raw_meas, aseg_vols, aseg_inds, meas_fsint_cort, meas_fsint_subcort, i, j, k
	, names.features, names.file.list, names.hemi, names.methods, opt.rois
	, project, folder.in, meas_fsaniso, meas_fsdldirect, meas_fsdlseg
	, meas_fsraw, meas_fsres, meas_fssynthsr)

save(list = ls(), file = 'rawdata_is.rdata')
