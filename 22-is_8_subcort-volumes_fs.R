rm(list = ls())
cat("\014")
source("22-is_functions.r")
load("metrics_is.rdata")

#The grouping variables are imported####

ptcvars <- read.delim("participants.csv", dec = ".", sep = ",", numerals = "no.loss")
ptcage <- t.test(ptcvars$Age_at_Scan ~ ptcvars$IGE)
ptcsex <- chisq.test(table(ptcvars$IGE, ptcvars$Sex))
ptcvars[ptcvars == "IGE"] <- 1
ptcvars[ptcvars == "M"] <- 1
ptcvars[ptcvars == "HC"] <- 0
ptcvars[ptcvars == "F"] <- 0
vars.male <- as.logical(as.numeric(ptcvars[["Sex"]]))
vars.scanage <- ptcvars[["Age_at_Scan"]]
vars.ptc <- as.logical(as.numeric(ptcvars[["IGE"]]))

#The prerequisites are created for the glm loop####

list_glm <- list()
mat_glmsig <- matrix(nrow = 5, ncol = 15)

#A for loop computes a glm for all of the subcortical volumes####

for (i in seq(1, 5)){
	k <- i*3
	vols <- meas[[k]][c(6:12, 19:25, 27)]
	for (j in 1:length(vols)){
		cellname <- paste(names(meas)[k], colnames(vols)[j], sep = '_')
		glm_ige <- glm(as.matrix(vols[j]) ~ vars.ptc + vars.male + vars.scanage)
		list_glm[[cellname]] <- summary(glm_ige)
		mat_glmsig[i,j] <- as.numeric(list_glm[[cellname]][[12]][2, 4])
	}
}

colnames(mat_glmsig) <- colnames(vols)
rownames(mat_glmsig) <- names(meas)[c(3, 6, 9, 12, 15)]

rm(cellname, i, j, k, glm_ige)

save(list_glm, mat_glmsig, file = "subcort-volumes_fs.rdata")
