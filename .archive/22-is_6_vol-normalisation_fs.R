rm(list = ls())
cat("\014")
library('psych')
load('rawdata_is.rdata')

sd <- list()
z_table <- list()
z_avg <- list()

for (i in seq(1, 3)){
	vals <- na.omit(meas[[i+6]])
	colmeans <- colMeans(vals)
	colsds <- c()
	for (j in 1:ncol(vals)){
		colsds[j] <- sqrt((sum((vals[, j] - colmeans[j])^2))/nrow(vals))
	}
	sd[[names(meas)[i+6]]] <- colsds
	for (k in c(0, 1, 3, 4)){
		l <- 3*k + i
		vals_2 <- na.omit(meas[[l]])
		zs <- vals_2
		for (j in 1:ncol(vals_2)){
			zs[, j] <- (vals_2[, j] - colmeans[j])/sd[[i]][j]
		}
		z_table[[names(meas)[l]]] <- zs
		z_avg[[names(meas)[l]]] <- colMeans(z_table[[names(meas)[l]]], na.rm = T)
	}
}

q <- c()
p <- c()
r <- c()
for (i in 1:length(z_avg)){
	q[i] <- min(z_avg[[i]])
	p[i] <- mean(z_avg[[i]])
	r[i] <- max(z_avg[[i]])
}
z_desc <- rbind(q, p, r)
colnames(z_desc) <- names(z_avg)
row.names(z_desc) <- c('min_z', 'mean_z', 'max_z')

rm(vals, vals_2, i, j, k, l, q, p, r, colsds, colmeans, zs)

save(list = ls(), file = "metrics_is.rdata")
