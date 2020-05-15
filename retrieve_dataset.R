# Load the data from the database to a local CSV

library(DBI)
source("api_keys.py")

con <- dbConnect(
	RPostgres::Postgres(),
	host = SQL_HOST,
	dbname = SQL_DB,
	user = SQL_USER,
	password = SQL_PASS
)

dataset <- tbl(con, "dataset") %>%
	collect()

dbDisconnect(con)
write_csv(dataset, "dataset.csv")