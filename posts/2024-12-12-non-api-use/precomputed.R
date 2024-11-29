library(data.table)

# The results are not reproducible because they depend on both the R-devel
# version and the data.table-git version, hence the pre-computation.

symbols <- fread(
	# most likely implies R on GNU/Linux built with --enable-R-shlib
	paste('nm -gDP', file.path(R.home('lib'), 'libR.so')),
	fill = TRUE, col.names = c('name', 'type', 'value', 'size')
)[
	type %in% c('B', 'D', 'R', 'T') # don't care about [weak] imports
][,
	type := fcase(
		type == 'B', 'variable',
		type == 'D', 'data',
		type == 'R', 'read-only data',
		type == 'T', 'function'
	)
][]

DTsymbols <- fread(
	# again, only tested on GNU/Linux
	paste('nm -gDP', system.file(
		file.path('libs', 'data_table.so'), package = 'data.table'
	)),
	fill = TRUE, col.names = c('name', 'type', 'value', 'size')
)[type %in% c('U', 'w')][,
	type := fcase(
		type == 'U', 'undefined',
		type == 'w', 'weak'
	)
][,
	name := sub('@.*', '', name)
][]

# this is entirely dependent on late-2024 tools:::{funAPI,nonAPI}
setdiff(
	# symbols exported by R and imported by data.table...
	intersect(symbols$name, DTsymbols$name) |>
		tools:::unmap(), # renamed according to how R API entry points are named
	# except those listed among API entry points
	tools:::funAPI()$name |> tools:::unmap()
) |> setdiff(
	# and also skip variables because they are omitted in funAPI
	symbols[type == 'variable', name]
) -> DTnonAPI
# which ones does R CMD check _not_ complain about... yet?
DTnonAPI_yet <- setdiff(DTnonAPI, tools:::nonAPI)

# History of tools:::nonAPI
getNonAPI <- function(ver,
	url = sprintf(
		"https://svn.r-project.org/R/branches/R-%s-branch/src/library/tools/R/sotools.R",
		ver
	)
) {
	ee <- parse(text = readLines(url))
	for (e in ee) {
		if (
			is.call(e) && length(e) == 3 &&
			identical(e[[1]], quote(`<-`)) &&
			identical(e[[2]], quote(`nonAPI`))
		)
		return(do.call(c, as.list(e[[3]])[-1]))
	}
}
nonAPI.3_3 <- getNonAPI('3-3')
nonAPI.4_4 <- getNonAPI('4-4')
nonAPI.trunk <- getNonAPI(url = 'https://svn.r-project.org/R/trunk/src/library/tools/R/sotools.R')

# CRAN package metadata and check results
cpdb <- tools::CRAN_package_db()
needscomp <- cpdb[,'NeedsCompilation'] == 'yes'
checks <- tools::CRAN_check_details()
dtchecks <- subset(checks, Package == 'data.table')

when <- Sys.Date()
save(
	needscomp, dtchecks, symbols, nonAPI.3_3, nonAPI.4_4, nonAPI.trunk,
	DTnonAPI, DTnonAPI_yet,
	when, file = 'precomputed.rda', compress = 'xz'
)
