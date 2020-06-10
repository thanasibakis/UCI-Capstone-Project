# Generate the demo for the Tensorflow Embedding Projector

source("api_keys.py")

library(DBI)
library(tidyverse)
library(plotly)

con <- dbConnect(
	RPostgres::Postgres(),
	host = SQL_HOST,
	dbname = SQL_DB,
	user = SQL_USER,
	password = SQL_PASS
)

lyrics <- tbl(con, "lyrics")
lyrics_features <- tbl(con, "lyrics_features")
uri <- tbl(con, "uri")

songs <- uri %>%
	left_join(lyrics, by = "uri") %>%
	left_join(lyrics_features, by = "uri") %>%
	mutate(title = title.y) %>%
	select(-c(title.y)) %>%
	collect() %>%
	drop_na()

songs %>%
	select(starts_with("min_embedding")) %>%
	write_tsv("TEP-demo/embeddings.tsv", col_names = F)

songs %>%
	select(title, artist) %>%
	write_tsv("TEP-demo/metadata.tsv")


dbDisconnect(con)
