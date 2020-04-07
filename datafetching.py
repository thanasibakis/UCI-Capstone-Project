#!/usr/bin/env python
# coding: utf-8

# In[1]:


import billboard
import lyricsgenius
import pandas as pd
import spotipy
import sqlalchemy as db
from datetime import datetime
from psaw import PushshiftAPI
from spotipy.oauth2 import SpotifyClientCredentials

from api_keys import *


# In[2]:


sp = spotipy.Spotify(client_credentials_manager = SpotifyClientCredentials(client_id = SPOTIFY_ID,
                                                                           client_secret = SPOTIFY_SECRET))

genius = lyricsgenius.Genius(GENIUS_ACCESS_TOKEN)
genius.verbose = False
genius.remove_section_headers = True

reddit = PushshiftAPI()

engine = db.create_engine(f"postgresql+psycopg2://{SQL_USER}:{SQL_PASS}@{SQL_HOST}/{SQL_DB}")
connection = engine.connect()


# Our API wrappers:

# In[3]:


def getSingleChart(date):
    chart = billboard.ChartData("hot-100", date = date)
    
    return pd.DataFrame( dict(song.__dict__, date = date) for song in chart )


def getSingleSongURI(title, artist):
    try:
        uri = sp.search(q = f"{title} {artist}", type = "track", limit = 1)["tracks"]["items"][0]["uri"]
        
        return {"uri":    uri,
                "title":  title,
                "artist": artist}
    
    except IndexError:
        return {"uri":    None,
                "title":  title,
                "artist": artist}


def getSingleSongFeatures(spotify_uri):
    features = sp.audio_features(spotify_uri)[0]
    
    if features is None:
        return {"uri": spotify_uri} # some kind of placeholder so we know it has no features
    
    return features


def getSingleSongLyrics(title, artist):
    song = genius.search_song(title = title, artist = artist)
    
    if song is None:
        return dict()
    
    return dict(song.to_dict())

    
def redditSearch(search_function, subreddit, from_date, to_date):
    start_date = datetime(*[ int(k) for k in from_date.split('-') ])
    start_epoch = int(start_date.timestamp())
    
    end_date = datetime(*[ int(k) for k in to_date.split('-') ])
    end_epoch = int(end_date.timestamp())

    results = search_function(after = start_epoch, before = end_epoch, subreddit = subreddit)
    
    return pd.DataFrame( row.d_ for row in results )


# Aggregating those calls:

# In[4]:


def getCharts(dates):
    return pd.concat( getSingleChart(date) for date in dates )

def getSongURIs(songs): # songs should be a table with columns "title" and "artist"
    return pd.DataFrame( getSingleSongURI(song.title, song.artist) for song in songs.itertuples() )

def getSongFeatures(spotify_uris):
    return pd.DataFrame( getSingleSongFeatures(uri) for uri in spotify_uris if uri is not None )

def getSongLyrics(songs):
    return pd.DataFrame( getSingleSongLyrics(song.title, song.artist) for song in songs.itertuples() )

def getPosts(subreddit, from_date, to_date):
    return redditSearch(reddit.search_submissions, subreddit, from_date, to_date)

def getComments(subreddit, from_date, to_date):
    return redditSearch(reddit.search_comments, subreddit, from_date, to_date)


# Fetching the data:

# In[13]:


months = [ f"{y}-{m:02d}-01" for y in range(2015, 2019+1) for m in range(1, 12+1) ]

print(months[0], "to", months[-1])


# In[6]:


chartsTable = getCharts(months)
chartsTable.to_sql("charts", connection, if_exists = "replace") # creates a new table

chartsTable


# In[7]:


songURIs = getSongURIs(chartsTable[["title", "artist"]].drop_duplicates())
songURIs.to_sql("uri", connection, if_exists = "replace")

songURIs


# In[ ]:


del chartsTable


# In[8]:


audioTable = getSongFeatures(songURIs.uri) # take the set in case songs are on the charts for many months
audioTable.to_sql("audio", connection, if_exists = "replace")

audioTable


# In[ ]:


del audioTable


# In[10]:


lyricsTable = getSongLyrics(songURIs) # slow, will replace with MusixMatch API
lyricsTable.to_sql("lyrics", connection, if_exists = "replace")

lyricsTable


# In[11]:


del lyricsTable


# In[12]:


postsTable = getPosts("news", months[0], months[-1])
postsTable.astype(str).to_sql("posts", connection, if_exists = "replace") # cast to string to insert dict objects

postsTable


# In[ ]:


del postsTable


# In[ ]:


commentsTable = getComments("news", months[0], months[-1])
commentsTable.astype(str).to_sql("comments", connection, if_exists = "replace")

commentsTable


# In[ ]:


del commentsTable


# In[ ]:


connection.close()

