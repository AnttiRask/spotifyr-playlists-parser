# Load libraries
library(dplyr)
library(lubridate)
library(readr)
library(spotifyr)
library(stringr)

# source("secret.R")

# Get the SpotifyAPI Access Token ----
# Sys.setenv(SPOTIFY_CLIENT_ID     = .SPOTIFY_CLIENT_ID)
# Sys.setenv(SPOTIFY_CLIENT_SECRET = .SPOTIFY_CLIENT_SECRET)
# access_token <- get_spotify_access_token()

access_token <- get_spotify_access_token(
    client_id     = Sys.getenv("SPOTIFY_CLIENT_ID"),
    client_secret = Sys.getenv("SPOTIFY_CLIENT_SECRET")
)

# Get the playlist ----
playlist <- get_playlist_tracks(
    playlist_id   = "37i9dQZEVXcEU5dKzCMv5W",
    authorization = access_token
) %>% as_tibble()

# Pull the artist names ----
artists <- playlist %>% pull(track.artists) %>% 
    bind_rows(.id = "song_id") %>% 
    slice_head(n = 1, by = "song_id") %>% 
    select(artist_name = name) %>%
    as_tibble()

# Pull the songs ----
songs <- playlist %>%
    mutate(
        date_added   = as_date(added_at),
        duration_s   = round(track.duration_ms / 1000, 0),
        release_year = if_else(
            track.album.release_date_precision == "year",
            as.numeric(track.album.release_date),
            year(as_date(track.album.release_date))
        )
    ) %>%
    select(
        song_name    = track.name,
        song_id      = track.id,
        duration_s,
        release_year,
        popularity   = track.popularity,
        date_added
    )

# Combine artists and songs ----
artists_and_songs <- artists %>%
    bind_cols(songs)

artists_and_songs

# Pull the date_added from the artists_and_songs ----
date_added <- artists_and_songs %>%
    distinct(date_added) %>%
    pull()

date_added

# Write the csv file ----
write_excel_csv2(
    artists_and_songs,
    file = str_c("weekly_discovers/", date_added, ".csv")
)