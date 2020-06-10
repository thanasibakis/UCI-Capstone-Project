# UCI Capstone Project

This is a UCI Data Science Undergraduate Capstone Project under the Stats 170A/B course. The project group consists of myself and Anjali Krishnan (@anjalik2).

The aim was to develop a system to examine a possible association between public sentiment as reflected in Reddit news posts, and the popularity of various songs as seen on online music charts. We hoped that knowledge of current events could provide insight as to the kinds of music that become of public interest at the same point in time.

## Project Pipeline

### Web Scraping & Feature Engineering

The `data_tools/` folder contains scripts that perform web scraping and feature engineering to create one dataset:

1. `data_tools/data_fetching.py` is first run to obtain the raw data and store it in various tables in a SQL database.
2. `data_tools/text_analysis.py` is then run to create model features from the text data collected.
3. `data_tools/create_features_tables.sql` is finally run to set up the schema for the full dataset table and populate this table with the appropriate data.

### Exploratory Data Analysis

The `EDA/` folder contains code to visualize aspects of the resulting dataset. Running these files is not necessary to fit any models.

1. `EDA/EDA_sentiment_scores.R` creates line plots of the news and music sentiment scores over time.
2. `EDA/word_embeddings.R` exports the music word embeddings for use with the Tensorflow Embeddings Projector.
    - This data is stored in `EDA/TEP-demo/`. Usage information can be found in our report.
    
### Modeling

The `models/` folder contains code to fit various models on the dataset. 

There are three models that we fit. Descriptions of each are described in the report. These models are in the form of `model[number].Rmd` and are meant to be knitted to observe model results. Each model is also exported to an `.html` file for convenient viewing.

Other items in this folder are:

- `models/model_template.Rmd`, a template file to easily create new model notebooks
- `models/saves/`, a directory for storing saved copies of the downloaded dataset and fitted models
   - This process is automatic during the knitting process. The first knit may take a while, but subsequent knits are quick.
- `models/includes/`, a directory containing `.Rmd` files with R chunks that are reused across several model notebooks.
   - These are imported into each model notebook to facilitate changes to the chunks. An include can be changed once and have its changes apply to all the model files.
   
### Report

Our final project report can be found in `.pdf` form in the `report/` folder, as well as its source as an `.Rmd` file.

### Demo for the Course Staff to Evaluate

The `demo_for_course_grading/` folder contains a simplified version of our best-performing model for the course staff to easily work with:

- `demo_for_course_grading/model2.Rmd` is a copy of the Model 2 notebook (with all the includes coded directly into the single file). This file can be run or knitted to observe results.
    - A `.html` version has been exported for viewing convenience.
- `demo_for_course_grading/dataset_20MB.csv` is a subset of our full dataset to faciltate quick evaluation.
- `demo_for_course_grading/*.rda` are model save files that facilitate quick knitting of the notebook.
