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


#dataset <- tbl(con, "dataset") %>%
#	collect()

# dbDisconnect(con)

#write_csv(dataset, "dataset.csv")

dataset <- read_csv("dataset.csv") %>%
	filter(lastpos != 0) # songs on the charts for the first time haven't changed rank


lm(
	I(rank < lastpos) ~ rank*songsentiment,
	data = dataset
) %>%
	summary()



formula <- paste(
	"I(rank < lastpos) ~ ",
	paste(
		sapply(
			1:300,
			function(i) paste("newsmin", i, " + newsmax", i, " + ", sep = '')
		),
		sep = '',
		collapse = '' # to paste together contents of the sapply vector
	),
	"newspositivity + newsnegativity + newsneutrality + newssentiment +",
	"songpositivity + songnegativity + songneutrality + songsentiment +",
	"acousticness + danceability + duration_ms + energy + instrumentalness +",
	"key + liveness + loudness + factor(mode) + speechiness + tempo +",
	"time_signature + valence +",
	"peakpos + weeks",
	sep = ''
)

# delta rank vs everything
# Y=TRUE implies popularity increased
glm(formula, data = dataset, family = "binomial") %>%
	summary()
