citations <- function(includeURL = TRUE, includeRStudio = TRUE) {
	if(includeRStudio == TRUE) {
		ref.rstudio <- RStudio.Version()$citation
		if(includeURL == FALSE) {
			ref.rstudio$url <- NULL;
		}
		print(ref.rstudio, style = 'text')
		cat('\n')
	}

	cit.list <- c('base', names(sessionInfo()$otherPkgs))
	for(i in 1:length(cit.list)) {
		ref <- citation(cit.list[i])
		if(includeURL == FALSE) {
			ref$url <- NULL;
		}
		print(ref, style = 'text')
		cat('\n')
	}
}

structural_prop.import <- function(folder.in, project) {

	names.file.list <- list.files(path=folder.in, full.names = T)
	names.methods <- gsub(paste(".*[/]", project, "[_](.*)[_].*[_].*[.].*", sep=""), "\\1", names.file.list[1:length(names.file.list)])
	names.hemi <-gsub(paste(".*[/]", project, "[_].*[_](.*)[_].*[.].*", sep=""), "\\1", names.file.list[1:length(names.file.list)])
	names.features <- gsub(paste(".*[/]", project, "[_].*[_].*[_](.*)[.].*", sep=""), "\\1", names.file.list[1:length(names.file.list)])
	raw_meas <- lapply(names.file.list, read.delim, header = T, dec = ".", numerals = "no.loss", row.names = 1)
	for (i in 1:length(raw_meas)){
		row.names(raw_meas[[i]]) <- gsub(".*[/](sub-[0-9][0-9][0-9]).*", "\\1", row.names(raw_meas[[i]]))
	}
	names(raw_meas) <- paste(names.methods, names.hemi, names.features, sep = "_")
	return(raw_meas)

}

structural_names.import <- function(folder.in, project) {

	names.file.list <- list.files(path=folder.in, full.names = T)
	names.methods <- gsub(paste(".*[/]", project, "[_](.*)[_].*[_].*[.].*", sep=""), "\\1", names.file.list[1:length(names.file.list)])
	names.hemi <-gsub(paste(".*[/]", project, "[_].*[_](.*)[_].*[.].*", sep=""), "\\1", names.file.list[1:length(names.file.list)])
	names.features <- gsub(paste(".*[/]", project, "[_].*[_].*[_](.*)[.].*", sep=""), "\\1", names.file.list[1:length(names.file.list)])
	raw_meas <- lapply(names.file.list, read.delim, header = T, dec = ".", numerals = "no.loss", row.names = 1)
	names(raw_meas) <- paste(names.methods, names.hemi, names.features, sep = "_")
	names.participants <- gsub(".*[/](sub-[0-9][0-9][0-9]).*", "\\1", row.names(raw_meas[[1]]))

	names <- list(names.file.list, names.methods, names.hemi, names.features, names.participants)
	names(names) <- c("paths", "methods", "hemi", "meas", "sub")

	return(names)

}
