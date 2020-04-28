import pandas as pd
import numpy as np
import sqlalchemy as db
import nltk
from datetime import datetime
from gensim.models import KeyedVectors
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
from nltk.corpus import wordnet
from nltk.stem.wordnet import WordNetLemmatizer
from nltk.sentiment.vader import SentimentIntensityAnalyzer

from api_keys import *

START_YEAR = 2010
END_YEAR   = 2019

PROCESS_LYRICS = False
PROCESS_POSTS = True

STOPWORDS = set(stopwords.words("english"))
model = KeyedVectors.load_word2vec_format("GoogleNews-vectors-negative300.bin", binary=True)


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
def text_features(text: str, index_value):
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
        .assign(**sentiment_features) \
        .assign(original_index=index_value)
        
def create_text_features(table, column_name):
    feature_rows = ( text_features(row[column_name], index) for index, row in table.iterrows() )
    table = pd.concat( row for row in feature_rows if row is not None ) \
        .set_index("original_index")

    return table
    


if __name__ == "__main__":
    engine = db.create_engine(f"postgresql+psycopg2://{SQL_USER}:{SQL_PASS}@{SQL_HOST}/{SQL_DB}")
    connection = engine.connect()


    # Lyrics processing
    
    if PROCESS_LYRICS:
        lyrics_table = pd.read_sql_query(f"select * from lyrics", connection)

        new_table = create_text_features(lyrics_table, "lyrics")
        new_table.to_sql(f"lyrics_scores", connection, if_exists="replace")

        del lyrics_table
        del new_table

    
    # Reddit posts processing

    if PROCESS_POSTS:
        months = [ f"{y}-{m:02d}-01" for y in range(START_YEAR, END_YEAR+1) for m in range(1, 12+1) ] + [ f"{END_YEAR+1}-01-01" ]
        
        should_create_table = True

        for i in range(len(months)-1):
            start_time = datetime.strptime(months[i], "%Y-%m-%d").timestamp()
            end_time = datetime.strptime(months[i+1], "%Y-%m-%d").timestamp()

            titles = pd.read_sql_query(f"select title from posts where created_utc::bigint >= {start_time} and created_utc::bigint < {end_time}", connection).title
            month_table = pd.DataFrame([{"month": months[i], "title_text": '\n'.join(titles)}]) \
                .set_index("month")
            
            new_table = create_text_features(month_table, "title_text")

            new_table.to_sql(f"posts_scores", connection, if_exists = "replace" if should_create_table else "append")
            should_create_table = False

            del month_table
            del new_table


    connection.close()

