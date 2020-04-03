CREATE TABLE charts (
	title text,
	artist text,
	image text,
	peakPos int,
	lastPos int,
	weeks int,
	rank int, 
	isNew boolean,
	date date,
    	spotify_uri text
);

CREATE TABLE audio (
    	danceability float,
    	energy float, 
    	key float,
    	loudness float,
    	mode float,
    	speechiness float,
    	acousticness float,
    	instrumentalness float,
    	livelieness float,
    	valence float,
    	tempo float,
	type text,
	id text,
	spotify_uri text,
	track_href text,
	analysis_url text,
    	duration_ms float,
    	time_signature float
);

CREATE TABLE lyrics (
	title text,
	album text,
	release_date date,
	lyrics text,
	image text,
    	spotify_uri text
);


CREATE TABLE posts (
	all_awardings text,
	allow_live_comments boolean,
	author text,
	author_flair_css_class text,
	author_flair_richtext text,
	author_flair_text text,
	author_flair_type text,
	author_fullname text,
	author_patreon_flair boolean,
	author_premium boolean,
	awarders text,
	can_mod_post boolean,
	contest_mode boolean,
	created_utc timestamp,
	domain text,
	full_link text,
	gildings text,
	id text,
	is_crosspostable boolean,
	is_meta boolean,
	is_original_content boolean,
	is_reddit_media_domain boolean,
	is_robot_indexable boolean,
	is_self boolean,
	is_video boolean,
	link_flair_background_color text,
	link_flair_richtext text,
	link_flair_template_id text,
	link_flair_text text,
	link_flair_text_color text,
	link_flair_type text,
	locked boolean,	
	media text,
	media_embed text,
	media_only boolean,
	no_follow boolean,
	num_comments int,
	num_crossposts int,
	over_18 boolean,
	parent_whitelist_status text,
	permalink text,
	pinned boolean,
	post_hint text,
	preview text,
	pwls float,
	retrieved_on timestamp,
	score float,
	secure_media text,
	secure_media_embed text,
	selftext text,
	send_replies boolean,
	spoiler boolean,
	stickied boolean,
	subreddit text,
	subreddit_id text,
	subreddit_subscribers int,
	subreddit_type text,
	thumbnail text,
	thumbnail_height float,
	thumbnail_width float,
	title text,
	total_awards_received int,
	url text,
	whitelist_status text,
	wls float

);

CREATE TABLE comments (
	all_awardings text,
	associated_award text,
	author text,
	author_flair_background_color text,
	author_flair_css_class text,
	author_flair_richtext text,
	author_flair_template_id text,
	author_flair_text text,
	author_flair_text_color text,
	author_flair_type text,
	author_fullname text,
	author_patreon_flair boolean,
	awarders text,
	body text,
	collapsed_because_crowd_control text,
	created_utc timestamp,
	gildings text,
	id text,
	is_submitter boolean,
	link_id text,
	locked boolean,
	no_follow boolean,
	parent_id text,
	permalink text,
	retrieved_on timestamp,
	score float,
	send_replies boolean,
	stickied boolean,
	subreddit text,
	subreddit_id text,
	total_awards_received int,
	distinguished text,
	author_cakeday text
);