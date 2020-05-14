# Load the data from the database to a local CSV
#library(DBI)
#source("api_keys.py")

#con <- dbConnect(
#	RPostgres::Postgres(),
#	host = SQL_HOST,
#	dbname = SQL_DB,
#	user = SQL_USER,
#	password = SQL_PASS
#)

#dataset <- tbl(con, "dataset") %>%
#	collect()

#dbDisconnect(con)
#write_csv(dataset, "dataset.csv")


library(magrittr)
library(plotROC)
library(plotly)
library(tidyverse)
library(glmnet)


# Retrieve the data saved from the database
dataset <- read_csv("dataset.csv") %>%
	filter(lastpos != 0) # songs on the charts for the first time haven't changed rank


# Our interaction terms will be defined as principal components (linear combinations of the original features)
PCA <- dataset %>%
	select(songpositivity,   songnegativity, songneutrality, songsentiment,
		   acousticness,     danceability,   duration_ms,    energy,
		   instrumentalness, key,            liveness,       loudness,
		   mode,             speechiness,    tempo,          time_signature,
		   valence,          peakpos,        weeks,
		   starts_with(c("songmin", "songmax")),

		   newspositivity,   newsnegativity, newsneutrality, newssentiment,
		   starts_with(c("newsmin", "newsmax"))) %>%
	prcomp()

features <- PCA %>%
	magrittr::extract2("x") %>%
	as.data.frame()


# try joining news/music features then doing pca on all of them
# so our intereactions are the linear combinations of the vars
# and also still do penalized/regularization bc 900 features for 8000 rows
# and also do pca plots


# Generate the model formula with all the interaction terms
formula <- colnames(features) %>%
	paste(collapse = " + ") %>%
	paste("response ~", . )


# Merge the two PCA data frames with the response values to get one dataset
features <- dataset %>%
	mutate(response = rank < lastpos) %>%
	select(response) %>%
	cbind(features)


# Train-test split
training_data <- features %>%
	sample_frac(0.5)

testing_data <- anti_join(features, training_data)


# Fit the model
#model <- glm(formula, data = training_data, family = "binomial")
model <- cv.glmnet(
	as.matrix(select(training_data, -response)),
	pull(training_data, response),
	family = "binomial"
)

plot(model)
coef(model)@i # index 1 (value 0) is the intercept

# https://stackoverflow.com/questions/29311323


# Make predictions and assess accuracy
predictions <- testing_data %>%
	mutate(soft_prediction = predict(model, newx = as.matrix(select(., -response)), type = "response")) %>%
	mutate(hard_prediction = soft_prediction >= 0.5) %>%
	mutate(is_correct      = hard_prediction == response)

paste("Accuracy:", round(mean(predictions$is_correct), 4))


# What is our test data's response distribution?
# What is our model's prediction distribution?
ggplotly(
	predictions %>%
		select(response, hard_prediction) %>%
		pivot_longer(
			c(response, hard_prediction),
			names_to = "Type",
			values_to = "Value"
		) %>%
		ggplot(aes(x = Value)) +
		geom_bar(aes(fill = Value)) +
		ylim(0, nrow(predictions)) +
		facet_wrap(
			~ Type,
			labeller = labeller(Type = c(hard_prediction = "Model Prediction", response = "True Value"))
		) +
		labs(title = "Distribution of response values and model predictions"),
	tooltip = c("y")
) %>%
	hide_legend()

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
	geom_roc(n.cuts = 20, labels = T, labelround = 2) +
	geom_abline(a = 1, b = 0)
