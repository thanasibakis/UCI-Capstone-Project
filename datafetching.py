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

# In[4]:


START_YEAR = 2019
END_YEAR   = 2019

months = [ f"{y}-{m:02d}-01" for y in range(START_YEAR, END_YEAR+1) for m in range(1, 12+1) ] + [ f"{END_YEAR+1}-01-01" ]

print("Getting data from", months[0], "to", months[-1])
print("______________________________________________")


# In[6]:


chartsTable = getCharts(months)
print("Fetched charts.")

chartsTable.to_sql("charts", connection, if_exists = "replace") # creates a new table
print("Sent charts to db.")

chartsTable


# In[7]:


songURIs = getSongURIs(chartsTable[["title", "artist"]].drop_duplicates())
print("Fetched song URIs.")

songURIs.to_sql("uri", connection, if_exists = "replace")
print("Sent song URIs to db..")

songURIs


# In[ ]:


del chartsTable


# In[2]:


audioTable = getSongFeatures(songURIs.uri) # take the set in case songs are on the charts for many months
print("Fetched audio features.")

audioTable.to_sql("audio", connection, if_exists = "replace")
print("Sent audio features to db.")

audioTable


# In[ ]:


del audioTable


# In[10]:


lyricsTable = getSongLyrics(songURIs) # slow, will replace with MusixMatch API
print("Fetched lyrics.")

lyricsTable.to_sql("lyrics", connection, if_exists = "replace")
print("Sent lyrics to db.")

lyricsTable


# In[11]:


del lyricsTable


# In[12]:


for i in range(0, len(months), 6): # we will run out of memory!
    startMonth = months[i]
    endMonth = months[i+6]
    
    postsTable = getPosts("news", startMonth, endMonth)
    print("Fetched posts.")

    postsTable.astype(str).to_sql("posts", connection, if_exists = "replace" if i == 0 else "append") # cast to string to insert dict objects
    print("Sent posts to db.")

    del postsTable


# In[ ]:


for i in range(0, len(months), 6):
    startMonth = months[i]
    endMonth = months[i+6]
    
    commentsTable = getComments("news", startMonth, endMonth)
    print("Fetched comments.")

    commentsTable.astype(str).to_sql("comments", connection, if_exists = "replace" if i == 0 else "append") # cast to string to insert dict objects
    print("Sent comments to db.")

    del commentsTable


# In[ ]:


connection.close()

