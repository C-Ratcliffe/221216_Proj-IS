#preamble####

rm(list = ls())
cat("\014")
source("22-is_functions.R")
library('ggplot2')
library('data.table')
library('ggsci')
load("metrics_is.rdata")

#data preparation####

data.thick <- melt(data.table(cbind(z_avg[[2]], z_avg[[3]], z_avg[[4]], z_avg[[5]]))
	, measure.vars = c(1, 2, 3, 4)
)

data.thick[, 1] <- c(rep('2D Scan', length(z_avg[[2]]))
	, rep('DL+DiReCT', length(z_avg[[3]]))
	, rep('Resampled', length(z_avg[[4]]))
	, rep('SynthSR', length(z_avg[[5]]))
)

data.cort <- melt(data.table(cbind(z_avg[[7]], z_avg[[8]], z_avg[[9]], z_avg[[10]]))
	, measure.vars = c(1, 2, 3, 4)
)
data.cort[, 1] <- c(rep('2D Scan', length(z_avg[[7]]))
	, rep('DL+DiReCT', length(z_avg[[8]]))
	, rep('Resampled', length(z_avg[[9]]))
	, rep('SynthSR', length(z_avg[[10]]))
)

data.sub <- melt(data.table(cbind(z_avg[[12]], z_avg[[13]], z_avg[[14]], z_avg[[15]]))
	, measure.vars = c(1, 2, 3, 4)
)
data.sub[, 1] <- c(rep('2D Scan', length(z_avg[[12]]))
	, rep('DL+DiReCT', length(z_avg[[13]]))
	, rep('Resampled', length(z_avg[[14]]))
	, rep('SynthSR', length(z_avg[[15]]))
)

#thickness plots - blackbg####

plot.thick <- ggplot(data.thick, aes(x = variable, y = value)
	)+
	geom_violin(trim = F
		, lwd = rel(1)
		, alpha = 0.8
		, aes(fill = variable, colour = variable, linetype = variable)
	)+
	geom_jitter(shape = 20
		, width = 0.05
		, colour = 'grey'
		, alpha = 0.8
	)+
	stat_summary(fun=mean
		, geom = 'point'
		, position = position_dodge(0.9)
		, shape = 5
		, size = 3
		, colour = 'black'
	)+
	scale_color_npg()+
	scale_fill_npg()+
	scale_y_continuous(limits = c(-8, 8)
		, breaks = c(8, 4, 0, -4, -8)
	)+
	labs(title = 'Regional Deviation in Thickness Estimations Across Image Types'
		, x = 'Image Type'
		, y = expression('Z-score')
	)+
	theme(text = element_text(family='sans', size = 12, colour = 'white')
		, legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major.y = element_line(colour = 'grey', linewidth = 0.25)
		, panel.grid.major.x = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, title = element_blank()
		, axis.text.x = element_blank()
		, axis.title.x = element_blank()
		, axis.text.y = element_text(colour = 'white', size = 8)
		, axis.title.y = element_blank()
		, axis.ticks = element_blank()
	)
filename <- 'F:/Working_Directory_Projects/Work/221216_Proj-IS/materials/figure-4/thick-blackbg'
ggsave(plot = plot.thick, device = 'svg', scale = 1, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.thick, device = 'png', scale = 1, units = 'px', filename = paste(filename, 'png', sep = '.'), dpi=300)

#thickness plots - nobg####

plot.thick <- plot.thick +
	theme(text = element_text(family='sans', size = 12, colour = 'black')
		, legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major.y = element_line(colour = 'grey', linewidth = 0.25)
		, panel.grid.major.x = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, title = element_blank()
		, axis.text.x = element_blank()
		, axis.title.x = element_blank()
		, axis.text.y = element_text(colour = 'black', size = 8)
		, axis.title.y = element_blank()
		, axis.ticks = element_blank()
	)
filename <- 'F:/Working_Directory_Projects/Work/221216_Proj-IS/materials/figure-4/thick-nobg'
ggsave(plot = plot.thick, device = 'svg', scale = 1, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.thick, device = 'png', scale = 1, units = 'px', filename = paste(filename, 'png', sep = '.'), dpi=300)

#cortical plots - blackbg####

plot.cort <- ggplot(data.cort, aes(x = variable, y = value)
)+
	geom_violin(trim = F
		, lwd = rel(1)
		, alpha = 0.8
		, aes(fill = variable, colour = variable, linetype = variable)
	)+
	geom_jitter(shape = 20
		, width = 0.05
		, colour = 'grey'
		, alpha = 0.8
	)+
	stat_summary(fun=mean
		, geom = 'point'
		, position = position_dodge(0.9)
		, shape = 5
		, size = 3
		, colour = 'black'
	)+
	scale_color_npg()+
	scale_fill_npg()+
	scale_y_continuous(limits = c(-4, 4)
		, breaks = c(4, 2, 0, -2, -4)
	)+
	labs(title = 'Regional Deviation in Cortical Volume Estimations Across Image Types'
		, x = 'Image Type'
		, y = expression('Z-score')
	)+
	theme(text = element_text(family='sans', size = 12, colour = 'white')
		, legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major.y = element_line(colour = 'grey', linewidth = 0.25)
		, panel.grid.major.x = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, title = element_blank()
		, axis.text.x = element_blank()
		, axis.title.x = element_blank()
		, axis.text.y = element_text(colour = 'white', size = 8)
		, axis.title.y = element_blank()
		, axis.ticks = element_blank()
	)
filename <- 'F:/Working_Directory_Projects/Work/221216_Proj-IS/materials/figure-4/cort-blackbg'
ggsave(plot = plot.cort, device = 'svg', scale = 1, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.cort, device = 'png', scale = 1, units = 'px', filename = paste(filename, 'png', sep = '.'), dpi=300)

#cortical plots - nobg####

plot.cort <- plot.cort +
	theme(text = element_text(family='sans', size = 12, colour = 'black')
		, legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major.y = element_line(colour = 'grey', linewidth = 0.25)
		, panel.grid.major.x = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, title = element_blank()
		, axis.text.x = element_blank()
		, axis.title.x = element_blank()
		, axis.text.y = element_text(colour = 'black', size = 8)
		, axis.title.y = element_blank()
		, axis.ticks = element_blank()
	)
filename <- 'F:/Working_Directory_Projects/Work/221216_Proj-IS/materials/figure-4/cort-nobg'
ggsave(plot = plot.cort, device = 'svg', scale = 1, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.cort, device = 'png', scale = 1, units = 'px', filename = paste(filename, 'png', sep = '.'), dpi=300)

#subcortical plots - blackbg####

plot.sub <- ggplot(data.sub, aes(x = variable, y = value)
)+
	geom_violin(trim = F
		, lwd = rel(1)
		, alpha = 0.8
		, aes(fill = variable, colour = variable, linetype = variable)
	)+
	geom_jitter(shape = 20
		, width = 0.05
		, colour = 'grey'
		, alpha = 0.8
	)+
	stat_summary(fun=mean
		, geom = 'point'
		, position = position_dodge(0.9)
		, shape = 5
		, size = 3
		, colour = 'black'
	)+
	scale_color_npg()+
	scale_fill_npg()+
	scale_y_continuous(limits = c(-4, 4)
		, breaks = c(4, 2, 0, -2, -4)
	)+
	labs(title = 'Regional Deviation in Subcortical Volume Estimations Across Image Types'
		, x = 'Image Type'
		, y = expression('Z-score')
	)+
	theme(text = element_text(family='sans', size = 12, colour = 'white')
		, legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major.y = element_line(colour = 'grey', linewidth = 0.25)
		, panel.grid.major.x = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, title = element_blank()
		, axis.text.x = element_blank()
		, axis.title.x = element_blank()
		, axis.text.y = element_text(colour = 'white', size = 8)
		, axis.title.y = element_blank()
		, axis.ticks = element_blank()
	)
filename <- 'F:/Working_Directory_Projects/Work/221216_Proj-IS/materials/figure-4/sub-blackbg'
ggsave(plot = plot.sub, device = 'svg', scale = 1, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.sub, device = 'png', scale = 1, units = 'px', filename = paste(filename, 'png', sep = '.'), dpi=300)

#subcortical plots - nobg####

plot.sub <- plot.sub +
	theme(text = element_text(family='sans', size = 12, colour = 'black')
		, legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major.y = element_line(colour = 'grey', linewidth = 0.25)
		, panel.grid.major.x = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, title = element_blank()
		, axis.text.x = element_blank()
		, axis.title.x = element_blank()
		, axis.text.y = element_text(colour = 'black', size = 8)
		, axis.title.y = element_blank()
		, axis.ticks = element_blank()
	)
filename <- 'F:/Working_Directory_Projects/Work/221216_Proj-IS/materials/figure-4/sub-nobg'
ggsave(plot = plot.sub, device = 'svg', scale = 1, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.sub, device = 'png', scale = 1, units = 'px', filename = paste(filename, 'png', sep = '.'), dpi=300)
