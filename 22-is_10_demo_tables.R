rm(list = ls())
cat("\014")
library('finalfit')
library('flextable')
library('officer')

#data import####
table.ptcvars <- read.table('F:/Working_Directory_Code/rstats/221216_Proj-IS/participants.csv', sep = ',', header = T)

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
ft.demos <- flextable(table.demos)

#width formatting####
ft.demos <- autofit(ft.demos)
ft.demos <- fit_to_width(ft.demos, 11) #0cm border fit

#table-specific formatting####
ft.demos <- ft.demos |>
	paginate(init = TRUE, hdr_ftr = TRUE) |>
	italic(j = 5, italic = T, part = "header") |>
	set_caption('Table 1. Age and Sex Comparisons.')

#themes####
ft.demos.zebra <- theme_zebra(
	ft.demos
	, odd_header = '#CFCFCF'
	, odd_body = '#EFEFEF'
	, even_header = 'white'
	, even_body = 'white'
)
save_as_image(
	ft.demos.zebra
	, path = 'F:/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-1/table-1.png'
	, res = 600
)

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
save_as_docx(
	ft.demos.zebra
	, path = 'F:/Working_Directory_Projects/Work/221216_Proj-IS/materials/table-1/table-1.docx'
	, pr_section = pr_sec
)
