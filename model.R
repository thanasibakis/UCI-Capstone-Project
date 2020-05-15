library(magrittr)
library(plotROC)
library(plotly)
library(tidyverse)


# Retrieve the data saved from the database
dataset <- read_csv("dataset.csv") %>%
	filter(lastpos != 0) # songs on the charts for the first time haven't changed rank


# Reduce dimensionality of song-related features
PCA_songs <- dataset %>%
	select(songpositivity,   songnegativity, songneutrality, songsentiment,
		   acousticness,     danceability,   duration_ms,    energy,
		   instrumentalness, key,            liveness,       loudness,
		   mode,             speechiness,    tempo,          time_signature,
		   valence,          peakpos,        weeks,
		   starts_with(c("songmin", "songmax"))) %>%
	prcomp() %>%
	magrittr::extract2("x") %>%
	magrittr::extract(, 1:30) %>%
	as.data.frame() %>%
	setNames(paste0("song_", colnames(.)))


# Reduce dimensionality of news-related features
PCA_news <- dataset %>%
	select(newspositivity,   newsnegativity, newsneutrality, newssentiment,
		   starts_with(c("newsmin", "newsmax"))) %>%
	prcomp() %>%
	magrittr::extract2("x") %>%
	magrittr::extract(, 1:30) %>%
	as.data.frame() %>%
	setNames(paste0("news_", colnames(.)))


# Generate the model formula with all the interaction terms
formula <- expand_grid(PC_song = colnames(PCA_songs), PC_news = colnames(PCA_news)) %>%
	mutate(interaction = paste(PC_song, PC_news, sep = ":")) %>%
	pull(interaction) %>%
	paste(collapse = " + ") %>%
	paste("response ~", . )


# Merge the two PCA data frames with the response values to get one dataset
features <- dataset %>%
	mutate(response = rank < lastpos) %>%
	select(response) %>%
	cbind(PCA_songs, PCA_news)


# Train-test split
training_data <- features %>%
	sample_frac(0.5)

testing_data <- anti_join(features, training_data)


# Fit the model
model <- glm(formula, data = training_data, family = "binomial")
summary(model)


# Make predictions and assess accuracy
predictions <- testing_data %>%
	mutate(soft_prediction = predict.glm(model, newdata = ., type = "response")) %>%
	mutate(hard_prediction = soft_prediction >= 0.5) %>%
	mutate(is_correct      = hard_prediction == response)

paste("Accuracy:", round(mean(predictions$is_correct), 2))


# How good are the hard predictions?
ggplotly(
	predictions %>%
		ggplot(aes(x = response, fill = hard_prediction)) +
		geom_bar(position = position_dodge()) +
		ylim(0, nrow(testing_data)) +
		labs(x = "True Response Value", fill = "Model Prediction")
)


# How good are the soft predictions?
ggplotly(
	predictions %>%
		ggplot(aes(y = soft_prediction, x = response)) +
		geom_boxplot() +
		labs(x = "True Value", y = "Model Predicted Probability")
)


# ROC curve to figure out which soft-->hard cutoff to use
predictions %>%
	ggplot(aes(m = soft_prediction, d = response)) +
	geom_roc(n.cuts = 20, labels = T, labelround = 2)