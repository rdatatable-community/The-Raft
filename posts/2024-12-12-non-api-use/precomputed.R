cpdb <- tools::CRAN_package_db()
checks <- subset(tools::CRAN_check_details(), Package == 'data.table')

when <- Sys.Date()
save(cpdb, checks, when, file = 'precomputed.rda')
