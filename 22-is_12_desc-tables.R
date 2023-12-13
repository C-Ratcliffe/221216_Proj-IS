#preamble####
rm(list = ls())
cat("\014")
library('flextable')
library('officer')

#word document properties####
p_size <- page_size(width = 29.7/2.54
	, height = 21/2.54
	, orient = "landscape"
)
p_mar <- page_mar(bottom = 1
	, top = 0
	, right = 0
	, left = 0
	, header = 0
	, footer = 0
	, gutter = 0
)
pr_sec <- prop_section(page_size = p_size
	, page_margins = p_mar
)

#data import - dev####
table.dev <- read.table('F:/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-2/dev.csv', sep = ',', header = T)

colnames(table.dev) <- c("  ", " ", "3D Scan", "2D Scan", "DL+DiReCT", "Resampled", "SynthSR")

#flextable defaults####
set_flextable_defaults(font.size = 12
	, font.family = 'Arial'
	, font.color = '#000000'
	, background.colour = 'white'
	, line_spacing = 1.25
	, layout = 'autofit'
	, padding.top = 3
	, padding.bottom = 3
	, rownames = TRUE
)
ft.dev <- flextable(table.dev)

#width formatting####
ft.dev <- autofit(ft.dev)
ft.dev <- fit_to_width(ft.dev, 11) #0cm border fit

#table-specific formatting####
ft.dev <- ft.dev |>
	paginate(init = TRUE, hdr_ftr = TRUE) |>
	set_caption('Table 2. Dice Scores, Deviations, and Intraclass Correlation Coefficients of Morphometrics Between Image Types')

#themes####
ft.dev.zebra <- theme_zebra(
	ft.dev
	, odd_header = '#CFCFCF'
	, odd_body = '#EFEFEF'
	, even_header = 'white'
	, even_body = 'white'
)

ft.dev.zebra <- ft.dev.zebra |>
	bg(i = c(1, 4, 5, 7, 8), bg = 'white', part = 'body') |>
	bg(i = c(2, 3, 6), bg = '#EFEFEF', part = 'body')

save_as_image(
	ft.dev.zebra
	, path = 'F:/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-2/table-2.png'
	, res = 600
)

save_as_docx(
	ft.dev.zebra
	, path = 'F:/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-2/table-3.docx'
	, pr_section = pr_sec
)

#data import - subcort####
table.subcort <- read.table('F:/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-3/min-pval.csv', sep = ',', header = T)

colnames(table.subcort) <- c("  ", " ", "3D Scan", "2D Scan", "Resampled", "SynthSR")

#flextable defaults####
set_flextable_defaults(font.size = 12
	, font.family = 'Arial'
	, font.color = '#000000'
	, background.colour = 'white'
	, line_spacing = 1.25
	, layout = 'autofit'
	, padding.top = 3
	, padding.bottom = 3
	, rownames = TRUE
)
ft.subcort <- flextable(table.subcort)

#width formatting####
ft.subcort <- autofit(ft.subcort)
ft.subcort <- fit_to_width(ft.subcort, 11) #0cm border fit

#table-specific formatting####
ft.subcort <- ft.subcort |>
	paginate(init = TRUE, hdr_ftr = TRUE) |>
	set_caption('Table 3. Maximal Significance of Subcortical Surface Shape Deflation Clusters in PWE, Observed in Different Image Types')

#themes####
ft.subcort.zebra <- theme_zebra(
	ft.subcort
	, odd_header = '#CFCFCF'
	, odd_body = '#EFEFEF'
	, even_header = 'white'
	, even_body = 'white'
)

ft.subcort.zebra <- ft.subcort.zebra |>
	bg(i = c(1, 2, 5, 6, 9, 10, 13, 14), bg = 'white', part = 'body') |>
	bg(i = c(3, 4, 7, 8, 11, 12), bg = '#EFEFEF', part = 'body')

save_as_image(
	ft.subcort.zebra
	, path = 'F:/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-3/table-3.png'
	, res = 600
)

save_as_docx(
	ft.subcort.zebra
	, path = 'F:/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-3/table-3.docx'
	, pr_section = pr_sec
)
