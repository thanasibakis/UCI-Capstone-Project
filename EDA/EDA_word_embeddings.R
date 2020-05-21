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

# # Accepts 2 rows of songs from the db, requiring title and embeddings
# get_distances <- function(songs)
# {
# 	min_embeddings <- songs %>%
# 		pivot_longer(
# 			cols = starts_with("min"),
# 			names_to = "embedding_number",
# 			names_prefix = "min_embedding",
# 			values_to = "min_embedding_value"
# 		) %>%
# 		select(title, embedding_number, min_embedding_value)

# 	max_embeddings <- songs %>%
# 		pivot_longer(
# 			cols = starts_with("max"),
# 			names_to = "embedding_number",
# 			names_prefix = "max_embedding",
# 			values_to = "max_embedding_value"
# 		) %>%
# 		select(title, embedding_number, max_embedding_value)

# 	song_embeddings <- full_join(min_embeddings, max_embeddings) %>%
# 		group_by(title) %>%
# 		group_split

# 	min_embedding_distance <- sum((song_embeddings[[1]]$min_embedding_value - song_embeddings[[2]]$min_embedding_value)^2)
# 	max_embedding_distance <- sum((song_embeddings[[1]]$max_embedding_value - song_embeddings[[2]]$max_embedding_value)^2)

# 	return(
# 		list(
# 			min_embedding_distance = min_embedding_distance,
# 			max_embedding_distance = max_embedding_distance
# 		)
# 	)
# }



# pos_two_songs <- songs %>%
# 	top_n(20, compound) %>%
# 	sample_n(2)

# neg_two_songs <- songs %>%
# 	top_n(20, -compound) %>%
# 	sample_n(2)

# mismatched_pair1 <- rbind(pos_two_songs[1, ], neg_two_songs[1, ])
# mismatched_pair2 <- rbind(pos_two_songs[2, ], neg_two_songs[2, ])

# # These should be smaller
# pos_two_songs %>% select(title, pos, neg, neu, compound)
# get_distances(pos_two_songs)

# neg_two_songs %>% select(title, pos, neg, neu, compound)
# get_distances(neg_two_songs)

# # These should be larger
# mismatched_pair1 %>% select(title, pos, neg, neu, compound)
# get_distances(mismatched_pair1)

# mismatched_pair2 %>% select(title, pos, neg, neu, compound)
# get_distances(mismatched_pair2)


# Generate the demo for the Tensorflow Embedding Projector

songs %>%
	select(starts_with("min_embedding")) %>%
	write_tsv("TEF-demo/embeddings.tsv", col_names = F)

songs %>%
	select(title, artist) %>%
	write_tsv("TEF-demo/metadata.tsv")


dbDisconnect(con)
