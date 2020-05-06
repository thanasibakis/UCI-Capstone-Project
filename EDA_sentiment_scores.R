source("api_keys.py")

library(DBI)
library(tidyverse)
library(plotly)

#con <- dbConnect(
#	RPostgres::Postgres(),
#	host = SQL_HOST,
#	dbname = SQL_DB,
#	user = SQL_USER,
#	password = SQL_PASS
#)

#dataset <- tbl(con, "dataset") %>%
#	collect()

# dbDisconnect(con)

#write_csv(dataset, "dataset.csv")

data <- read_csv("dataset.csv") %>%
	filter(lastpos != 0) # songs on the charts for the first time haven't changed rank


ggplotly(
	data %>%
		select(newsmonth, newspositivity, newsnegativity) %>%
		collect() %>%
		pivot_longer(c(newspositivity, newsnegativity), names_to = "score") %>%
		ggplot(aes(x = newsmonth, y = value, grp = score, col = score)) +
		geom_line() +
		labs(title = "Sentiment Scores of News", x = "Month", y = "Sentiment Score") +
		theme(text = element_text(size = 18)) +
		ylim(c(0, 0.3))
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
		geom_line() +
		labs(title = "Sentiment Scores of Song Charts", x = "Month", y = "Sentiment Score") +
		theme(text = element_text(size = 18)) +
		ylim(c(0, 0.3))
)

# meanwhile, a massive decline in chart negativity begain in April 2013,
# and a decently sharp increase in chart positivity coincides with it



#dbDisconnect(con)

