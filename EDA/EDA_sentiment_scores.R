library(tidyverse)
library(extrafont)


data <- read_csv("models/saves/dataset.csv")


data %>%
	select(newsmonth, newspositivity, newsnegativity) %>%
	pivot_longer(c(newspositivity, newsnegativity), names_to = "score") %>%
	ggplot(aes(x = newsmonth, y = value, grp = score, col = score)) +
	geom_line() +
	labs(title = "Sentiment Scores of News", x = "Month", y = "Sentiment Score") +
  theme(
    text = element_text(size = 14, family = "Roboto Light"),
    plot.title = element_text(size = 20)
  ) +
	ylim(c(0, 0.3))

ggsave("news_plot.svg", width=10, height=6) #hidpi export


# news was most negative in the month of April 2013
# and got significantly less negative in the month of May 2013

data %>%
	select(chartmonth, songpositivity, songnegativity) %>%
	group_by(chartmonth) %>%
	summarise(chartpositivity = mean(songpositivity),
			  chartnegativity = mean(songnegativity)) %>%
	pivot_longer(c(chartpositivity, chartnegativity), names_to = "score") %>%
	ggplot(aes(x = chartmonth, y = value, grp = score, col = score)) +
	geom_line() +
	labs(title = "Sentiment Scores of Song Charts", x = "Month", y = "Sentiment Score") +
  theme(
    text = element_text(size = 14, family = "Roboto Light"),
    plot.title = element_text(size = 20)
  ) +
	ylim(c(0, 0.3))

ggsave("music_plot.svg", width=10, height=6) #hidpi export

# meanwhile, a massive decline in chart negativity begain in April 2013,
# and a decently sharp increase in chart positivity coincides with it
