rm(list = ls())
cat('\014')
source('22-is_functions.R')

#The data is imported and the names/indices are extracted####

folder.in <- "measurements_fs"
project <- "is"
opt.rois <- 148

names.file.list <- list.files(path=folder.in, full.names = T)
names.meas <-  gsub(".*[/](.*)[.]csv", "\\1", names.file.list[1:length(names.file.list)])
raw_meas <- lapply(names.file.list, read.table, header = T, dec = ".", numerals = "no.loss", sep = ",")
region_labels <- read.delim('resources/vol_regions.csv', sep = ',')

#The aseg parcellations are matched####

names(raw_meas) <- names.meas
raw_meas[["dldirect-aseg_volume"]] <- raw_meas[["dldirect-aseg_volume"]][,-30]
aseg_inds <- c(51, 1, 2, 18, 3, 5, 6, 7, 8, 12, 13, 15, 16, 52, 19, 20, 32, 21, 23, 24, 25, 26, 27, 28, 29, 30, 11, 9, 10, 41)

for (i in c('iso', 'aniso', 'synthsr', 'res')){
	aseg_vols <- raw_meas[names.meas == paste(i, '-aseg_volume', sep = '')][[1]]
	aseg_vols[,3] <- aseg_vols[,3] + aseg_vols[,4]
	aseg_vols[,21] <- aseg_vols[,21] + aseg_vols[22]
	aseg_vols[,41] <- aseg_vols[,41] + aseg_vols[42] + aseg_vols[43] + aseg_vols[44] + aseg_vols[45]
	aseg_vols <- aseg_vols[, aseg_inds]
	raw_meas[names.meas == paste(i, '-aseg_volume', sep = '')][[1]] <- aseg_vols
}

meas <- raw_meas

#Intermediary files are removed and the rawdata are saved####

rm(raw_meas, aseg_vols, aseg_inds, i, names.file.list, opt.rois)

save(list = ls(), file = 'rawdata_is.rdata')
