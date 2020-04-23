import pandas as pd
import sqlalchemy as db

import nltk
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
from nltk.corpus import wordnet
from nltk.stem.wordnet import WordNetLemmatizer
from nltk.sentiment.vader import SentimentIntensityAnalyzer

from api_keys import *

STOPWORDS = set(stopwords.words("english"))

def get_db_table(table_name):
    engine = db.create_engine(f"postgresql+psycopg2://{SQL_USER}:{SQL_PASS}@{SQL_HOST}/{SQL_DB}")
    connection = engine.connect()

    table = pd.read_sql_query(f"select * from {table_name}", connection)

    connection.close()

    return table

def send_to_db_table(table_name, df):
    engine = db.create_engine(f"postgresql+psycopg2://{SQL_USER}:{SQL_PASS}@{SQL_HOST}/{SQL_DB}")
    connection = engine.connect()

    df.to_sql(table_name, connection, if_exists = "replace")

    connection.close()

# https://www.machinelearningplus.com/nlp/lemmatization-examples-python/
def get_part_of_speech(word):
    tag = nltk.pos_tag([word])[0][1][0].upper()
    tag_dict = {
        "J": wordnet.ADJ,
        "N": wordnet.NOUN,
        "V": wordnet.VERB,
        "R": wordnet.ADV
    }

    return tag_dict.get(tag, wordnet.NOUN)

# lemmatizing words - reducing words to their base word
def lemmatize_words(tokenized_words: list):
    lem = WordNetLemmatizer()

    return [ lem.lemmatize(w, get_part_of_speech(w)) for w in tokenized_words if w not in STOPWORDS ]

def text_scores(text: str):
    if not text:
        return (0, 0, 0, 0)

    sid = SentimentIntensityAnalyzer()
    
    tokenized_words = word_tokenize(text)
    lemmatized_words = lemmatize_words(tokenized_words)
    words_text = ' '.join(lemmatized_words)
    text_scores = sid.polarity_scores(words_text)

    return text_scores.values()

def create_text_features(table_name, column_name):
    table = get_db_table(table_name)

    table["neg"] = 0.0
    table["neu"] = 0.0
    table["pos"] = 0.0
    table["compound"] = 0.0

    for index, row in table.iterrows():
        table.loc[index, ['neg', 'neu', 'pos', 'compound']] = text_scores(row[column_name])

    send_to_db_table(f"{table_name}_scores", table)


if __name__ == "__main__":
    create_text_features("lyrics", "lyrics")

