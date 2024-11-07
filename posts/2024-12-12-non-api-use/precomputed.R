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

cpdb %<-% tools::CRAN_package_db()
checks %<-% subset(tools::CRAN_check_details(), Package == 'data.table')

when <- Sys.Date()
save(cpdb, checks, symbols, when, file = 'precomputed.rda', compress = 'xz')
