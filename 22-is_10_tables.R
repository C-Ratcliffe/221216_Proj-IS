#preamble####
rm(list = ls())
cat("\014")
library('finalfit')
library('flextable')
library('officer')
library('sysfonts')

#word document properties####
p_size <- page_size(width = 29.7/2.54
	, height = 21/2.54
	, orient = "portrait"
)
p_mar <- page_mar(bottom = 1
	, top = 1
	, right = 1
	, left = 1
	, header = 0
	, footer = 0
	, gutter = 0
)
pr_sec <- prop_section(page_size = p_size
	, page_margins = p_mar
)

#flextable defaults####

set_flextable_defaults(background.colour = 'white'
	, font.size = 18
	, font.family = 'Roboto Light'
	, font.color = '#000000'
	, layout = 'autofit'
	, line_spacing = 1.25
	, padding.top = 3
	, padding.bottom = 3
	, rownames = TRUE
)

#data import - dev####

table.dev <- read.table('C:/Users/coreyar/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-1/dev.csv', sep = ',', header = T)

colnames(table.dev) <- c("  ", " ", "3D Scan", "2D Scan", "DL+DiReCT", "Resampled", "SynthSR")

ft.dev <- flextable(table.dev)
ft.dev <- theme_zebra(ft.dev
	, odd_header = '#CFCFCF'
	, odd_body = '#EFEFEF'
	, even_header = 'white'
	, even_body = 'white'
)

#table-specific formatting####

ft.dev <- autofit(ft.dev)
ft.dev <- fit_to_width(ft.dev, 16.002, unit = 'cm')

ft.dev <- ft.dev |>
	paginate(init = TRUE, hdr_ftr = TRUE) |>
	bold(bold = F, part = 'header') |>
	fontsize(size = 12, part = 'body') |>
	set_caption('Table 1. Dice Scores, Deviations, and Intraclass Correlation Coefficients of Morphometrics Between Image Types')

ft.dev <- ft.dev |>
	bg(i = c(1, 4, 5, 7, 8), bg = 'white', part = 'body') |>
	bg(i = c(2, 3, 6), bg = '#EFEFEF', part = 'body')

save_as_image(
	ft.dev
	, path = 'C:/Users/coreyar/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-1/table-1.png'
	, res = 600
)

save_as_docx(
	ft.dev
	, path = 'C:/Users/coreyar/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-1/table-1.docx'
	, pr_section = pr_sec
)

#data import - demos####

table.ptcvars <- read.table('C:/Users/coreyar/Working_Directory_Code/rstats/221216_Proj-IS/resources/participants.csv', sep = ',', header = T)

table.demos <- summary_factorlist(table.ptcvars
	, 'IGE'
	, c('Age_at_Scan', 'Sex')
	, p = T
	, na_include = F
	, digits = c(2,2,3,2,0)
	, include_col_totals_percent = FALSE
)
colnames(table.demos) <- c("  ", " ", "HC (n = 39)", "PWE (n = 31)", "p =")
table.demos[1,1] <- "Age at Scan"

ft.demos <- flextable(table.demos)
ft.demos <- theme_zebra(ft.demos
	, odd_header = '#CFCFCF'
	, odd_body = '#EFEFEF'
	, even_header = 'white'
	, even_body = 'white'
)

#table-specific formatting####

ft.demos <- autofit(ft.demos)
ft.demos <- fit_to_width(ft.demos, 16.002, unit = 'cm')

ft.demos <- ft.demos |>
	paginate(init = TRUE, hdr_ftr = TRUE) |>
	italic(j = 5, italic = T, part = "header") |>
	bold(bold = F, part = 'header') |>
	fontsize(size = 12, part = 'body') |>
	set_caption('Table 1. Age and Sex Comparisons.')

save_as_image(
	ft.demos
	, path = 'C:/Users/coreyar/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-2/table-2.png'
	, res = 600
)

save_as_docx(
	ft.demos
	, path = 'C:/Users/coreyar/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-2/table-2.docx'
	, pr_section = pr_sec
)

#data import - ptc.hc####
table.ptc.hc <- read.table('C:/Users/coreyar/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-3/min-pval.csv', sep = ',', header = T, colClasses = 'character')

colnames(table.ptc.hc) <- c("  ", " ", "3D Scan", "2D Scan", "Resampled", "SynthSR")

ft.ptc.hc <- flextable(table.ptc.hc)
ft.ptc.hc <- theme_zebra(ft.ptc.hc
	, odd_header = '#CFCFCF'
	, odd_body = '#EFEFEF'
	, even_header = 'white'
	, even_body = 'white'
)

#table-specific formatting####

ft.ptc.hc <- autofit(ft.ptc.hc)
ft.ptc.hc <- fit_to_width(ft.ptc.hc, 16.002, unit = 'cm')

ft.ptc.hc <- ft.ptc.hc |>
	paginate(init = TRUE, hdr_ftr = TRUE) |>
	bold(bold = F, part = 'header') |>
	fontsize(size = 12, part = 'body') |>
	set_caption('Table 3. Maximal Significance of Subcortical Surface Shape Deflation Clusters in PWE, Observed in Different Image Types')

ft.ptc.hc <- ft.ptc.hc |>
	bg(i = c(1, 2, 5, 6, 9, 10, 13, 14), bg = 'white', part = 'body') |>
	bg(i = c(3, 4, 7, 8, 11, 12), bg = '#EFEFEF', part = 'body')

save_as_image(
	ft.ptc.hc
	, path = 'C:/Users/coreyar/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-3/table-3.png'
	, res = 600
)

save_as_docx(
	ft.ptc.hc
	, path = 'C:/Users/coreyar/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-3/table-3.docx'
	, pr_section = pr_sec
)

#data import - hc.ptc (hc-ptc)####
table.hc.ptc <- read.table('C:/Users/coreyar/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-4/min-pval.csv', sep = ',', header = T, colClasses = 'character')

colnames(table.hc.ptc) <- c("  ", " ", "3D Scan", "2D Scan", "Resampled", "SynthSR")

ft.hc.ptc <- flextable(table.hc.ptc)
ft.hc.ptc <- theme_zebra(ft.hc.ptc
	, odd_header = '#CFCFCF'
	, odd_body = '#EFEFEF'
	, even_header = 'white'
	, even_body = 'white'
)

#table-specific formatting####

ft.hc.ptc <- autofit(ft.hc.ptc)
ft.hc.ptc <- fit_to_width(ft.hc.ptc, 16.002, unit = 'cm')

ft.hc.ptc <- ft.hc.ptc |>
	paginate(init = TRUE, hdr_ftr = TRUE) |>
	bold(bold = F, part = 'header') |>
	fontsize(size = 12, part = 'body') |>
	set_caption('Table 4. Maximal Significance of Subcortical Surface Shape Inflation Clusters in PWE, Observed in Different Image Types')

ft.hc.ptc <- ft.hc.ptc |>
	bg(i = c(1, 2, 5, 6, 9, 10, 13, 14), bg = 'white', part = 'body') |>
	bg(i = c(3, 4, 7, 8, 11, 12), bg = '#EFEFEF', part = 'body')

save_as_image(
	ft.hc.ptc
	, path = 'C:/Users/coreyar/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-4/table-4.png'
	, res = 600
)

save_as_docx(
	ft.hc.ptc
	, path = 'C:/Users/coreyar/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-4/table-4.docx'
	, pr_section = pr_sec
)
