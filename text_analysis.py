import pandas as pd
import numpy as np
import sqlalchemy as db
import nltk
from gensim.models import KeyedVectors
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
from nltk.corpus import wordnet
from nltk.stem.wordnet import WordNetLemmatizer
from nltk.sentiment.vader import SentimentIntensityAnalyzer

from api_keys import *

STOPWORDS = set(stopwords.words("english"))
model = KeyedVectors.load_word2vec_format("GoogleNews-vectors-negative300.bin", binary=True)

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

# Gives 604 features: 300 minimum word embedding, 300 max word embed, 4 sentiment scores
def text_features(text: str):
    if not text:
        return None

    sid = SentimentIntensityAnalyzer()
    
    tokenized_words = word_tokenize(text)
    lemmatized_words = lemmatize_words(tokenized_words)

    words_text = ' '.join(lemmatized_words)
    sentiment_features = sid.polarity_scores(words_text)

    word_embeddings = np.array([ model[word] for word in lemmatized_words if word in model.vocab ])

    min_embedding = pd.DataFrame(word_embeddings.min(axis=0)).T
    min_embedding.columns = (f"min_embedding{i+1}" for i in range(300))

    max_embedding = pd.DataFrame(word_embeddings.max(axis=0)).T
    max_embedding.columns = (f"max_embedding{i+1}" for i in range(300))

    # Create one long row
    return pd.concat((min_embedding, max_embedding), axis=1) \
        .assign(**sentiment_features)

def create_text_features(table_name, column_name):
    orig_table = get_db_table(table_name)

    # Merge the long rows
    feature_rows = ( text_features(row[column_name]).assign(original_index = index) for index, row in orig_table.iterrows() )
    table = pd.concat(filter(lambda row: row is not None, feature_rows)) \
        .set_index("original_index")

    send_to_db_table(f"{table_name}_scores", table)


if __name__ == "__main__":
    create_text_features("lyrics", "lyrics")

