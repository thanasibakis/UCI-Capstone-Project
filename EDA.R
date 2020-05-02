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

data <- tbl(con, "dataset")
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
	filter(artist == "Ariana Grande") %>%
	arrange(-pos) %>%
	collect() %>%
	print(n = nrow(.))






# Accepts 2 rows of songs from the db, requiring title and embeddings
get_distances <- function(songs)
{
	min_embeddings <- songs %>%
		pivot_longer(
			cols = starts_with("min"),
			names_to = "embedding_number",
			names_prefix = "min_embedding",
			values_to = "min_embedding_value"
		) %>%
		select(title, embedding_number, min_embedding_value)

	max_embeddings <- songs %>%
		pivot_longer(
			cols = starts_with("max"),
			names_to = "embedding_number",
			names_prefix = "max_embedding",
			values_to = "max_embedding_value"
		) %>%
		select(title, embedding_number, max_embedding_value)

	song_embeddings <- full_join(min_embeddings, max_embeddings) %>%
		group_by(title) %>%
		group_split

	min_embedding_distance <- sum((song_embeddings[[1]]$min_embedding_value - song_embeddings[[2]]$min_embedding_value)^2)
	max_embedding_distance <- sum((song_embeddings[[1]]$max_embedding_value - song_embeddings[[2]]$max_embedding_value)^2)

	return(
		list(
			min_embedding_distance = min_embedding_distance,
			max_embedding_distance = max_embedding_distance
		)
	)
}



pos_two_songs <- songs %>%
	top_n(20, compound) %>%
	sample_n(2)

neg_two_songs <- songs %>%
	top_n(20, -compound) %>%
	sample_n(2)

mismatched_pair1 <- rbind(pos_two_songs[1, ], neg_two_songs[1, ])
mismatched_pair2 <- rbind(pos_two_songs[2, ], neg_two_songs[2, ])

# These should be smaller
pos_two_songs %>% select(title, pos, neg, neu, compound)
get_distances(pos_two_songs)

neg_two_songs %>% select(title, pos, neg, neu, compound)
get_distances(neg_two_songs)

# These should be larger
mismatched_pair1 %>% select(title, pos, neg, neu, compound)
get_distances(mismatched_pair1)

mismatched_pair2 %>% select(title, pos, neg, neu, compound)
get_distances(mismatched_pair2)





songs %>%
	select(starts_with("min_embedding")) %>%
	write_tsv("embeddings.tsv", col_names = F)

songs %>%
	select(title, artist) %>%
	write_tsv("metadata.tsv")

# http://projector.tensorflow.org/?config=https://gist.githubusercontent.com/thanasibakis/8c52564194e59bdbc8fa448ff036ea74/raw/5fe3276152b6514ecbc74e1b8452b123d6f7f52b/template_projector_config.json





ggplotly(
	data %>%
		select(newsmonth, newspositivity, newsnegativity) %>%
		collect() %>%
		pivot_longer(c(newspositivity, newsnegativity), names_to = "score") %>%
		ggplot(aes(x = newsmonth, y = value, grp = score, col = score)) +
		geom_line()
)

# news was most negative in the month of April 2013
# and got significantly less negative in the month of May 2013

ggplotly(
	data %>%
		select(chartmonth, songpositivity, songnegativity) %>%
		group_by(chartmonth) %>%
		summarise(chartpositivity = mean(songpositivity),
				  chartnegativity = mean(songnegativity)) %>%
		collect() %>%
		pivot_longer(c(chartpositivity, chartnegativity), names_to = "score") %>%
		ggplot(aes(x = chartmonth, y = value, grp = score, col = score)) +
		geom_line()
)

# meanwhile, a massive decline in chart negativity begain in April 2013,
# and a decently sharp increase in chart positivity coincides with it



dbDisconnect(con)

