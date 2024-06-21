#preamble####

rm(list = ls())
cat("\014")
source("22-is_functions.R")
library('ggplot2')
library('data.table')
library('ggsci')
load("metrics_is.rdata")

#data preparation####

data.thick <- melt(data.table(cbind(z_avg[[5]], z_avg[[6]], z_avg[[7]], z_avg[[8]]))
	, measure.vars = c(1, 2, 3, 4)
)

data.thick[, 1] <- c(rep('2D Scan', length(z_avg[[5]]))
	, rep('DL+DiReCT', length(z_avg[[6]]))
	, rep('Resampled', length(z_avg[[7]]))
	, rep('SynthSR', length(z_avg[[8]]))
)

data.cort <- melt(data.table(cbind(z_avg[[9]], z_avg[[10]], z_avg[[11]], z_avg[[12]]))
	, measure.vars = c(1, 2, 3, 4)
)

data.cort[, 1] <- c(rep('2D Scan', length(z_avg[[9]]))
	, rep('DL+DiReCT', length(z_avg[[10]]))
	, rep('Resampled', length(z_avg[[11]]))
	, rep('SynthSR', length(z_avg[[12]]))
)

data.sub <- melt(data.table(cbind(z_avg[[1]], z_avg[[2]], z_avg[[3]], z_avg[[4]]))
	, measure.vars = c(1, 2, 3, 4)
)
data.sub[, 1] <- c(rep('2D Scan', length(z_avg[[1]]))
	, rep('DL+DiReCT', length(z_avg[[2]]))
	, rep('Resampled', length(z_avg[[3]]))
	, rep('SynthSR', length(z_avg[[4]]))
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
		, breaks = c(8, 6, 4, 2, 0, -2, -4, -6, -8)
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
		, plot.margin = unit(c(0, 0, 0, 0), "cm")
		, title = element_blank()
		, axis.text.x = element_blank()
		, axis.title.x = element_blank()
		, axis.text.y = element_text(colour = 'white', size = 8)
		, axis.title.y = element_blank()
		, axis.ticks = element_blank()
	)
filename <- 'C:/Users/coreyar/Working_Directory_Projects/Diagrams/221216_Proj-IS/figure-4/thick-blackbg'
ggsave(plot = plot.thick, device = 'svg', height = 4800, width = 2400, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.thick, device = 'png', height = 4800, width = 2400, units = 'px', filename = paste(filename, 'png', sep = '.'), dpi=300)

#thickness plots - whitebg####

plot.thick <- plot.thick +
	theme(text = element_text(family='sans', size = 12, colour = 'black')
		, legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major.y = element_line(colour = 'grey', linewidth = 0.25)
		, panel.grid.major.x = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, plot.margin = unit(c(0, 0, 0, 0), "cm")
		, title = element_blank()
		, axis.text.x = element_blank()
		, axis.title.x = element_blank()
		, axis.text.y = element_text(colour = 'black', size = 8)
		, axis.title.y = element_blank()
		, axis.ticks = element_blank()
	)
filename <- 'C:/Users/coreyar/Working_Directory_Projects/Diagrams/221216_Proj-IS/figure-4/thick-whitebg'
ggsave(plot = plot.thick, device = 'svg', height = 4800, width = 2400, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.thick, device = 'png', height = 4800, width = 2400, units = 'px', filename = paste(filename, 'png', sep = '.'), dpi=300)

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
		, plot.margin = unit(c(1, 0, 0, 0), "cm")
		, title = element_blank()
		, axis.text.x = element_blank()
		, axis.title.x = element_blank()
		, axis.text.y = element_text(colour = 'white', size = 8)
		, axis.title.y = element_blank()
		, axis.ticks = element_blank()
	)
filename <- 'C:/Users/coreyar/Working_Directory_Projects/Diagrams/221216_Proj-IS/figure-4/cort-blackbg'
ggsave(plot = plot.cort, device = 'svg', height = 2400, width = 2400, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.cort, device = 'png', height = 2400, width = 2400, units = 'px', filename = paste(filename, 'png', sep = '.'), dpi=300)

#cortical plots - whitebg####

plot.cort <- plot.cort +
	theme(text = element_text(family='sans', size = 12, colour = 'black')
		, legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major.y = element_line(colour = 'grey', linewidth = 0.25)
		, panel.grid.major.x = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, plot.margin = unit(c(1, 0, 0, 0), "cm")
		, title = element_blank()
		, axis.text.x = element_blank()
		, axis.title.x = element_blank()
		, axis.text.y = element_text(colour = 'black', size = 8)
		, axis.title.y = element_blank()
		, axis.ticks = element_blank()
	)
filename <- 'C:/Users/coreyar/Working_Directory_Projects/Diagrams/221216_Proj-IS/figure-4/cort-whitebg'
ggsave(plot = plot.cort, device = 'svg', height = 2400, width = 2400, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.cort, device = 'png', height = 2400, width = 2400, units = 'px', filename = paste(filename, 'png', sep = '.'), dpi=300)

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
		, plot.margin = unit(c(0, 0, 1, 0), "cm")
		, title = element_blank()
		, axis.text.x = element_blank()
		, axis.title.x = element_blank()
		, axis.text.y = element_text(colour = 'white', size = 8)
		, axis.title.y = element_blank()
		, axis.ticks = element_blank()
	)
filename <- 'C:/Users/coreyar/Working_Directory_Projects/Diagrams/221216_Proj-IS/figure-4/sub-blackbg'
ggsave(plot = plot.sub, device = 'svg', height = 2400, width = 2400, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.sub, device = 'png', height = 2400, width = 2400, units = 'px', filename = paste(filename, 'png', sep = '.'), dpi=300)

#subcortical plots - whitebg####

plot.sub <- plot.sub +
	theme(text = element_text(family='sans', size = 12, colour = 'black')
		, legend.position = 'none'
		, panel.grid.minor = element_blank()
		, panel.grid.major.y = element_line(colour = 'grey', linewidth = 0.25)
		, panel.grid.major.x = element_blank()
		, panel.background = element_blank()
		, plot.background = element_blank()
		, plot.margin = unit(c(0, 0, 1, 0), "cm")
		, title = element_blank()
		, axis.text.x = element_blank()
		, axis.title.x = element_blank()
		, axis.text.y = element_text(colour = 'black', size = 8)
		, axis.title.y = element_blank()
		, axis.ticks = element_blank()
	)
filename <- 'C:/Users/coreyar/Working_Directory_Projects/Diagrams/221216_Proj-IS/figure-4/sub-whitebg'
ggsave(plot = plot.sub, device = 'svg', height = 2400, width = 2400, units = 'px', filename = paste(filename, 'svg', sep = '.'), dpi=300)
ggsave(plot = plot.sub, device = 'png', height = 2400, width = 2400, units = 'px', filename = paste(filename, 'png', sep = '.'), dpi=300)
