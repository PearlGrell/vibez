from ytmusicapi import YTMusic
import json

ytMusic = YTMusic()
song = ytMusic.search('Ice cream', filter="songs")[0]

videoId = song['videoId']
res_get_songs = ytMusic.get_watch_playlist(videoId)
res_credit = ytMusic.get_song_credits(videoId)
with open("file.json", "w") as file:
    file.write(json.dumps(res_get_songs, indent=2))