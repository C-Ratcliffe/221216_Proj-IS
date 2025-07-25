rm(list = ls())
cat("\014")

library('psych')
library('lme4')
library('ggplot2')
library('tidyr')
library('svglite')
library('extrafont')

load('metrics_is.rdata')
loadfonts(device = "win", quiet = TRUE)

meas_sub <- c(meas[1], meas[4], meas[7], meas[10], meas[13])
meas_thick <- c(meas[2], meas[5], meas[8], meas[11], meas[14])
meas_cort <- c(meas[3], meas[6], meas[9], meas[12], meas[15])

#Intraclass correlation coefficient####

list_thick <- list()
list_iccthick <- list()
for (i in c(1, 2, 4, 5)){
	for (j in seq(1, 148, 1)){
		data <- cbind(meas_thick[[3]][,j], meas_thick[[i]][,j])
		cellname <- paste(names(meas_thick)[i], names(meas_thick[[i]])[j], sep = '_')
		list_thick[[cellname]] <- ICC(data, lmer = T)
		list_iccthick[[cellname]] <- as.numeric(list_thick[[cellname]][[1]][2, 2])
	}
}
mat_thick <- matrix(unlist(list_iccthick), 148, 4, dimnames = list(region_labels[31:178, 2], c('an', 'dl', 'res', 'ssr')))

list_cort <- list()
list_icccort <- list()
for (i in c(1, 2, 4, 5)){
	for (j in seq(1, 148, 1)){
		data <- cbind(meas_cort[[3]][,j], meas_cort[[i]][,j])
		cellname <- paste(names(meas_cort)[i], names(meas_cort[[i]])[j], sep = '_')
		list_cort[[cellname]] <- ICC(data, lmer = T)
		list_icccort[[cellname]] <- as.numeric(list_cort[[cellname]][[1]][2, 2])
	}
}
mat_cort <- matrix(unlist(list_icccort), 148, 4, dimnames = list(region_labels[31:178, 2], c('an', 'dl', 'res', 'ssr')))

list_sub <- list()
list_iccsub <- list()
for (i in c(1, 2, 4, 5)){
	for (j in seq(1, 30, 1)){
		data <- cbind(meas_sub[[3]][,j], meas_sub[[i]][,j])
		cellname <- paste(names(meas_sub)[i], names(meas_sub[[i]])[j], sep = '_')
		list_sub[[cellname]] <- ICC(data, lmer = T)
		list_iccsub[[cellname]] <- as.numeric(list_sub[[cellname]][[1]][2, 2])
	}
}
mat_sub <- matrix(unlist(list_iccsub), 30, 4, dimnames = list(region_labels[1:30, 2], c('an', 'dl', 'res', 'ssr')))

rm(cellname, i, j, list_iccthick, list_icccort, list_iccsub)

icc_cort <- colMeans(mat_cort)
icc_sub <- colMeans(mat_sub)
icc_thick <- colMeans(mat_thick)

#Cortical Volume Correlations####

cortvol_an <- gather(data = meas_cort[[1]])
cortvol_dl <- gather(data = meas_cort[[2]])
cortvol_iso <- gather(data = meas_cort[[3]])
cortvol_res <- gather(data = meas_cort[[4]])
cortvol_ssr <- gather(data = meas_cort[[5]])

cortvol_all <- cbind(cortvol_iso, cortvol_an[,2], cortvol_dl[,2], cortvol_res[,2], cortvol_ssr[,2])

colnames(cortvol_all) <- c('Regions', '3D Scan Measurements', '2D Scan', 'DL+DiReCT', 'Resampled', 'SynthSR')

cortvol_long <- pivot_longer(cortvol_all, cols = c('2D Scan', 'DL+DiReCT', 'Resampled', 'SynthSR'), names_to = 'Image', values_to = 'Estimated Cortical Volumes')

rm(cortvol_raw, cortvol_an, cortvol_dl, cortvol_res, cortvol_ssr, cortvol_all)

##whitebg

plot.cort <- ggplot(cortvol_long
	, aes(x = `3D Scan Measurements`
		, y = `Estimated Cortical Volumes`
		, z = `Regions`
	)
)+
	geom_abline(linewidth = 0.5
		, colour = 'grey'
	)+
	stat_smooth(method = 'lm'
		, fullrange = F
		, level = 0
		, colour = 'black'
	)+
	xlim(0, 33000
	)+
	ylim(0, 33000
	)+
	theme(legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, plot.tag = element_blank()
		, plot.title = element_blank()
		, axis.text.y = element_text(angle = 90, size = 15, colour = 'black', family = 'Roboto Light', hjust = 0.5)
		, axis.text.x = element_text(size = 15, colour = 'black', family = 'Roboto Light')
		, axis.title.y = element_blank()
		, axis.title.x = element_blank()
		, axis.ticks = element_line(colour = 'black')
		, axis.line = element_line(colour = 'black')
	)+
	facet_wrap(. ~ `Image`, nrow = 1
	)+
	theme(strip.text = element_blank()
		, strip.background = element_blank()
	)

filename <- "C:/Users/coreyar/Working_Directory_Projects/Diagrams/221216_Proj-IS/figure-6/vol_whitebg"
ggsave(plot = plot.cort, device = 'svg', scale = 1, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.cort, device = 'png', height = 1200, width = 4800, units = 'px', filename = paste(filename, 'png', sep = '.'))

##blackbg

plot.cort <- plot.cort +
	stat_smooth(method = 'lm'
		, fullrange = F
		, level = 0
		, colour = 'white'
	)+
	theme(legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, plot.tag = element_blank()
		, plot.title = element_blank()
		, axis.text.y = element_text(angle = 90, size = 15, colour = 'white', family = 'Roboto Light', hjust = 0.5)
		, axis.text.x = element_text(size = 15, colour = 'white', family = 'Roboto Light')
		, axis.title.y = element_blank()
		, axis.title.x = element_blank()
		, axis.ticks = element_line(colour = 'white')
		, axis.line = element_line(colour = 'white')
	)+
	facet_wrap(. ~ `Image`, nrow = 1
	)+
	theme(strip.text = element_blank()
		, strip.background = element_blank()
	)

filename <- "C:/Users/coreyar/Working_Directory_Projects/Diagrams/221216_Proj-IS/figure-6/vol_blackbg"
ggsave(plot = plot.cort, device = 'svg', scale = 1, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.cort, device = 'png', height = 1200, width = 4800, units = 'px', filename = paste(filename, 'png', sep = '.'))

#Subcortical Volume Correlations####

subvol_an <- gather(data = meas_sub[[1]])
subvol_dl <- gather(data = meas_sub[[2]])
subvol_iso <- gather(data = meas_sub[[3]])
subvol_res <- gather(data = meas_sub[[4]])
subvol_ssr <- gather(data = meas_sub[[5]])

subvol_all <- cbind(subvol_iso, subvol_an[,2], subvol_dl[,2], subvol_res[,2], subvol_ssr[,2])

colnames(subvol_all) <- c('Regions', '3D Scan Measurements', '2D Scan', 'DL+DiReCT', 'Resampled', 'SynthSR')

subvol_long <- pivot_longer(subvol_all, cols = c('2D Scan', 'DL+DiReCT', 'Resampled', 'SynthSR'), names_to = 'Image', values_to = 'Estimated Subcortical Volumes')

rm(subvol_iso, subvol_an, subvol_dl, subvol_res, subvol_ssr, subvol_all)

##whitebg

plot.sub <- ggplot(subvol_long
	, aes(x = `3D Scan Measurements`
		, y = `Estimated Subcortical Volumes`
		, z = `Regions`
	)
)+
	geom_abline(linewidth = 0.5
		, colour = 'grey'
	)+
	stat_smooth(method = 'lm'
		, fullrange = F
		, level = 0
		, colour = 'black'
	)+
	xlim(0, 70000
	)+
	ylim(0, 70000
	)+
	theme(legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, plot.tag = element_blank()
		, plot.title = element_blank()
		, axis.text.y = element_text(angle = 90, size = 15, colour = 'black', family = 'Roboto Light', hjust = 0.5)
		, axis.text.x = element_text(size = 15, colour = 'black', family = 'Roboto Light')
		, axis.title.y = element_blank()
		, axis.title.x = element_blank()
		, axis.ticks = element_line(colour = 'black')
		, axis.line = element_line(colour = 'black')
	)+
	facet_wrap(. ~ `Image`, nrow = 1
	)+
	theme(strip.text = element_blank()
		, strip.background = element_blank()
	)

filename <- "C:/Users/coreyar/Working_Directory_Projects/Diagrams/221216_Proj-IS/figure-6/sub_whitebg"
ggsave(plot = plot.sub, device = 'svg', scale = 1, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.sub, device = 'png', height = 1200, width = 4800, units = 'px', filename = paste(filename, 'png', sep = '.'))

##blackbg

plot.sub <- plot.sub +
	stat_smooth(method = 'lm'
		, fullrange = F
		, level = 0
		, colour = 'white'
	)+
	theme(legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, plot.tag = element_blank()
		, plot.title = element_blank()
		, axis.text.y = element_text(angle = 90, size = 15, colour = 'white', family = 'Roboto Light', hjust = 0.5)
		, axis.text.x = element_text(size = 15, colour = 'white', family = 'Roboto Light')
		, axis.title.y = element_blank()
		, axis.title.x = element_blank()
		, axis.ticks = element_line(colour = 'white')
		, axis.line = element_line(colour = 'white')
	)+
	facet_wrap(. ~ `Image`, nrow = 1
	)+
	theme(strip.text = element_blank()
		, strip.background = element_blank()
	)

filename <- "C:/Users/coreyar/Working_Directory_Projects/Diagrams/221216_Proj-IS/figure-6/sub_blackbg"
ggsave(plot = plot.sub, device = 'svg', scale = 1, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.sub, device = 'png', height = 1200, width = 4800, units = 'px', filename = paste(filename, 'png', sep = '.'))

#Cortical Thickness Correlations####

cortthick_an <- gather(data = meas_thick[[1]])
cortthick_dl <- gather(data = meas_thick[[2]])
cortthick_iso <- gather(data = meas_thick[[3]])
cortthick_res <- gather(data = meas_thick[[4]])
cortthick_ssr <- gather(data = meas_thick[[5]])

cortthick_all <- cbind(cortthick_iso, cortthick_an[,2], cortthick_dl[,2], cortthick_res[,2], cortthick_ssr[,2])

colnames(cortthick_all) <- c('Regions', '3D Scan Measurements', '2D Scan', 'DL+DiReCT', 'Resampled', 'SynthSR')

cortthick_long <- pivot_longer(cortthick_all, cols = c('2D Scan', 'DL+DiReCT', 'Resampled', 'SynthSR'), names_to = 'Image', values_to = 'Estimated Cortical Thickness')

rm(cortthick_iso, cortthick_an, cortthick_dl, cortthick_res, cortthick_ssr, cortthick_all)

### whitebg

plot.thick <- ggplot(cortthick_long
	, aes(x = `3D Scan Measurements`
		, y = `Estimated Cortical Thickness`
		, z = `Regions`
	)
)+
	geom_abline(linewidth = 0.5
		, colour = 'grey'
	)+
	stat_smooth(method = 'lm'
		, fullrange = F
		, level = 0
		, colour = 'black'
	)+
	xlim(0, 5
	)+
	ylim(0, 5
	)+
	theme(legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, plot.tag = element_blank()
		, plot.title = element_blank()
		, axis.text.y = element_text(angle = 90, size = 15, colour = 'black', family = 'Roboto Light', hjust = 0.5)
		, axis.text.x = element_text(size = 15, colour = 'black', family = 'Roboto Light')
		, axis.title.y = element_blank()
		, axis.title.x = element_blank()
		, axis.ticks = element_line(colour = 'black')
		, axis.line = element_line(colour = 'black')
	)+
	facet_wrap(. ~ `Image`, nrow = 1
	)+
	theme(strip.text = element_blank()
		, strip.background = element_blank()
	)

filename <- "C:/Users/coreyar/Working_Directory_Projects/Diagrams/221216_Proj-IS/figure-6/thick_whitebg"
ggsave(plot = plot.thick, device = 'svg', scale = 1, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.thick, device = 'png', height = 1200, width = 4800, units = 'px', filename = paste(filename, 'png', sep = '.'))

### blackbg

plot.thick <- plot.thick +
	stat_smooth(method = 'lm'
		, fullrange = F
		, level = 0
		, colour = 'white'
	)+
	theme(legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, plot.tag = element_blank()
		, plot.title = element_blank()
		, axis.text.y = element_text(angle = 90, size = 15, colour = 'white', family = 'Roboto Light', hjust = 0.5)
		, axis.text.x = element_text(size = 15, colour = 'white', family = 'Roboto Light')
		, axis.title.y = element_blank()
		, axis.title.x = element_blank()
		, axis.ticks = element_line(colour = 'white')
		, axis.line = element_line(colour = 'white')
	)+
	facet_wrap(. ~ `Image`, nrow = 1
	)+
	theme(strip.text = element_blank()
		, strip.background = element_blank()
	)

filename <- "C:/Users/coreyar/Working_Directory_Projects/Diagrams/221216_Proj-IS/figure-6/thick_blackbg"
ggsave(plot = plot.thick, device = 'svg', scale = 1, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.thick, device = 'png', height = 1200, width = 4800, units = 'px', filename = paste(filename, 'png', sep = '.'))

# Example scatterplot####

raw_region <- meas_cort[[1]][,4]
an_region <- meas_cort[[2]][,4]
scatter_data <- data.frame(raw_region, an_region)

### whitebg

plot.egscatter <- ggplot(scatter_data
	, aes(x = `an_region`
		, y = `raw_region`
	)
)+
	geom_point(size = 1
		, colour = 'black'
	)+
	stat_smooth(method = 'lm'
		, fullrange = F
		, level = 0
		, colour = 'black'
	)+
	labs(x = '2D Scan'
		, y = '3D Scan'
	)+
	xlim(2000, 4500
	)+
	ylim(2000, 4500
	)+
	theme(legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, plot.tag = element_blank()
		, plot.title = element_blank()
		, axis.text.y = element_text(angle = 90, size = 10, colour = 'black', family = 'Roboto Light', hjust = 0.5)
		, axis.text.x = element_text(size = 10, colour = 'black', family = 'Roboto Light')
		, axis.title.y = element_blank()
		, axis.title.x = element_blank()
		, axis.ticks = element_line(colour = 'black')
		, axis.line = element_line(colour = 'black')
	)

filename <- "C:/Users/coreyar/Working_Directory_Projects/Diagrams/221216_Proj-IS/figure-6/archive/example_scatter_whitebg"
#ggsave(plot = plot.egscatter, device = 'svg', scale = 1, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
#ggsave(plot = plot.egscatter, device = 'png', scale = 1, units = 'px', filename = paste(filename, 'png', sep = '.'), dpi=300)

### blackbg

plot.egscatter <- plot.egscatter +
	geom_point(size = 1
		, colour = 'white'
	)+
	stat_smooth(method = 'lm'
		, fullrange = F
		, level = 0
		, colour = 'white'
	)+
	theme(legend.position = 'none'
		, axis.text.y = element_text(angle = 90, size = 10, colour = 'white', family = 'Roboto Light', hjust = 0.5)
		, axis.text.x = element_text(size = 10, colour = 'white', family = 'Roboto Light')
		, axis.ticks = element_line(colour = 'white')
		, axis.line = element_line(colour = 'white')
	)

filename <- "C:/Users/coreyar/Working_Directory_Projects/Diagrams/221216_Proj-IS/figure-6/archive/example_scatter_blackbg"
#ggsave(plot = plot.egscatter, device = 'svg', scale = 1, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
#ggsave(plot = plot.egscatter, device = 'png', scale = 1, units = 'px', filename = paste(filename, 'png', sep = '.'), dpi=300)
