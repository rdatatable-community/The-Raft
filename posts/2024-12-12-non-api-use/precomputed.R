library(depcache) # TODO: uncache everything before submission
library(data.table)

symbols %<-% fread(
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

getNonAPI <- function(ver,
	url = sprintf(
		"https://svn.r-project.org/R/branches/R-%s-branch/src/library/tools/R/sotools.R",
		ver
	)
) {
	ee <- parse(text = cache(
		readLines(url)
	))
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

cpdb %<-% tools::CRAN_package_db()
needscomp <- cpdb[,'NeedsCompilation'] == 'yes'
checks %<-% tools::CRAN_check_details()
dtchecks <- subset(checks, Package == 'data.table')

when <- Sys.Date()
save(
	needscomp, dtchecks, symbols, nonAPI.3_3, nonAPI.4_4, nonAPI.trunk,
	when, file = 'precomputed.rda', compress = 'xz'
)
