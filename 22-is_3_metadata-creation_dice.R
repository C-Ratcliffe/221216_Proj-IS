rm(list = ls())
cat("\014")
source("22-is_functions.r")

ctx_regions <- read.delim('resources/aparc.ctab', sep = '', header = F)
sctx_regions <- read.delim('resources/aseg.txt', sep = '', header = F)

subs <- c(1:112)
for (i in subs){
	subs[i] <- sprintf('%03d', i)
	subs[i] <- paste('sub-', subs[i], sep = '')
}

lctx <- t(ctx_regions[2:76,1:2])
rctx <- t(ctx_regions[2:76,1:2])
sctx <- t(sctx_regions[,1:2])
sctx[1,] <- as.numeric(sctx[1,])

for (i in 1:75){
	lctx[1,i] <- as.numeric(lctx[1,i]) + 11100
	lctx[2,i] <- paste('ctx_lh_', lctx[2,i], sep='')
	rctx[1,i] <- as.numeric(rctx[1,i]) + 12100
	rctx[2,i] <- paste('ctx_rh_', rctx[2,i], sep = '')
}

ints <- cbind(sctx, lctx, rctx)[1,]
labels <- cbind(sctx, lctx, rctx)[2,]

write.csv(subs, 'resources/dice_subs.csv', row.names = F, quote = F)
write.csv(ints, 'resources/dice_ints.csv', row.names = F, quote = F)
write.csv(labels, 'resources/dice_labels.csv', row.names = F, quote = F)

rm(ctx_regions, sctx_regions, i, lctx, rctx, sctx)
