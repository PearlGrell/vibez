from app.ytmusic_client import ytmusic
from app.thumbnail import get_best_thumbnail
import yt_dlp
import grpc
from generated import song_pb2
from cachetools import TTLCache

import os
import shutil
import time
from urllib.parse import urlparse, parse_qs
from yt_dlp.utils import DownloadError

# yt-dlp rewrites the cookie file on close to persist refreshed session
# cookies. Render/HF mount secret files read-only, so point yt-dlp at a
# writable copy (re-seeded from the secret each boot).
_WRITABLE_COOKIES = "/tmp/vibez_cookies.txt"

class SongService:
    URL_SAFETY_MARGIN = 300

    YDL_OPTS = {
        "format": "bestaudio/best",
        "quiet": True,
        "no_warnings": True,
        "noplaylist": True,
        # Innertube clients skip the youtube.com watch page, where datacenter
        # IPs get bot-checked first. Bot checks are per video AND per client,
        # so list several: yt-dlp falls through to the next on failure.
        "extractor_args": {"youtube": {"player_client": ["android_vr", "android", "tv"]}},
    }
    
    def __init__(self):
        self.track_cache = TTLCache(
            maxsize=10000,
            ttl=3600
        )
        self.url_cache = TTLCache(
            maxsize=10000,
            ttl=21600
        )
        self.album_cache = TTLCache(
            maxsize=10000,
            ttl=3600
        )
        self.credit_cache = TTLCache(
            maxsize=10000,
            ttl=3600
        )
        self.lyrics_cache = TTLCache(
            maxsize=10000,
            ttl=3600
        )

    def get_track(self, video_id):
        if video_id in self.track_cache:
            return self.track_cache[video_id]

        track = ytmusic.get_watch_playlist(video_id)
        self.track_cache[video_id] = track

        return track
    
    def get_album(self, album_id):
        if album_id in self.album_cache:
            return self.album_cache[album_id]

        album = ytmusic.get_album(album_id)
        self.album_cache[album_id] = album

        return album
    
    def get_credits(self, credit_id):
        if credit_id in self.credit_cache:
            return self.credit_cache[credit_id]
        
        try:
            credits = ytmusic.get_song_credits(credit_id)
            self.credit_cache[credit_id] = credits
            return credits
        except Exception:
            return {}
    
    def get_lyrics(self, lyrics_id):
        if lyrics_id in self.lyrics_cache:
            return self.lyrics_cache[lyrics_id]

        try:
            lyrics_data = ytmusic.get_lyrics(browseId=lyrics_id, timestamps=True)
        except (KeyError, TypeError):
            lyrics_data = ytmusic.get_lyrics(browseId=lyrics_id, timestamps=False)
        self.lyrics_cache[lyrics_id] = lyrics_data
        return lyrics_data
    
    @staticmethod
    def convert_duration(time: str) -> int:
        parts = list(map(int, time.split(":")))

        if len(parts) == 2:
            minutes, seconds = parts
            return minutes * 60 + seconds

        if len(parts) == 3:
            hours, minutes, seconds = parts
            return hours * 3600 + minutes * 60 + seconds

        raise ValueError(f"Invalid duration format: {time}")
    
    def song(self, request, context):
        video_id = request.id
        playlist = self.get_track(video_id)
        tracks = playlist.get("tracks", [])

        if not tracks:
            context.abort(
                grpc.StatusCode.NOT_FOUND,
                "Track not found"
            )

        track = tracks[0]
    
        artists = [
            song_pb2.SongArtist(
                name=artist.get("name", ""),
                id=artist.get("id") or ""
            )
            for artist in track.get("artists", [])
            if artist
        ]
        thumbnail_url = get_best_thumbnail(track.get("thumbnail") or [])
        return song_pb2.SongResponse(
            id=video_id,
            title=track.get("title", ""),
            artists=artists,
            album=(track.get("album") or {}).get("name", ""),
            albumId=(track.get("album") or {}).get("id", ""),
            duration=self.convert_duration(track.get("length", "0:00")),
            thumbnail=thumbnail_url,
            year=track.get("year", "")
        )

    @staticmethod
    def _url_expiry(url: str) -> int:
        try:
            exp = parse_qs(urlparse(url).query).get("expire", [None])[0]
            return int(exp) if exp else 0
        except Exception:
            return 0

    @staticmethod
    def _cookie_path():
        src = os.environ.get("COOKIES_FILE")
        if not src or not os.path.exists(src):
            return None
        try:
            if not os.path.exists(_WRITABLE_COOKIES):
                shutil.copyfile(src, _WRITABLE_COOKIES)
            return _WRITABLE_COOKIES
        except Exception:
            return None

    @staticmethod
    def _build_opts(proxy=None):
        opts = dict(SongService.YDL_OPTS)
        cookiefile = SongService._cookie_path()
        if cookiefile:
            # A logged-in session bypasses the datacenter "confirm you're not a
            # bot" wall AND satisfies PO-token gating, so authenticated web URLs
            # download fully. Let yt-dlp use its default (web) clients, which is
            # what actually consumes cookies — the anonymous android_vr set does
            # not, so drop the restriction when cookies are present.
            opts["cookiefile"] = cookiefile
            opts.pop("extractor_args", None)
        if proxy:
            opts["proxy"] = proxy
        return opts

    @staticmethod
    def _extract(video_id, proxy=None):
        opts = SongService._build_opts(proxy)
        watch_url = f"https://www.youtube.com/watch?v={video_id}"
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(watch_url, download=False)
        ext = info.get("ext", "mp4")
        mime = "audio/mp4" if ext in ("m4a", "mp4") else f"audio/{ext}"
        url = info.get("url", "")
        return url, mime, SongService._url_expiry(url)

    @staticmethod
    def resolve_url(video_id):
        try:
            return SongService._extract(video_id, proxy=None)
        except DownloadError:
            proxy = os.environ.get("YTDLP_PROXY")
            if not proxy:
                raise
            return SongService._extract(video_id, proxy=proxy)
        

    def audio(self, request, context):
        video_id = request.id
        now = time.time()

        cached = self.url_cache.get(video_id)
        if cached:
            playback_url, mime_type, expire_ts = cached
            if expire_ts == 0 or expire_ts - now > self.URL_SAFETY_MARGIN:
                return song_pb2.AudioResponse(
                    id=video_id, playbackUrl=playback_url, mimeType=mime_type
                )

        try:
            playback_url, mime_type, expire_ts = self.resolve_url(video_id)
        except DownloadError as e:
            context.abort(grpc.StatusCode.UNAVAILABLE, f"Could not resolve audio: {e}")

        self.url_cache[video_id] = (playback_url, mime_type, expire_ts)
        return song_pb2.AudioResponse(
            id=video_id, playbackUrl=playback_url, mimeType=mime_type
        )
        
    def lyrics(self, request, context):
        video_id = request.id
        playlist = self.get_track(video_id)
        lyrics_id = playlist.get("lyrics")
        if not lyrics_id:
           return song_pb2.LyricsResponse(
               lyrics = [],
               source = "",
               hasTimestamps = False
           )
        
        lyrics_data = self.get_lyrics(lyrics_id)
        if not lyrics_data:
            return song_pb2.LyricsResponse(
               lyrics = [],
               source = "",
               hasTimestamps = False
            )
            
        lyrics_val = lyrics_data.get("lyrics")
        has_timestamps = lyrics_data.get("hasTimestamps", False)

        if has_timestamps and isinstance(lyrics_val, list):
            lyrics_blocks = [
                song_pb2.LyricBlock(
                    text=line.text if hasattr(line, "text") else line.get("text", ""),
                    startTime=(
                        getattr(line, "start_time", 0)
                        if hasattr(line, "text")
                        else line.get("start_time", 0)
                    ),
                    endTime=(
                        getattr(line, "end_time", 0)
                        if hasattr(line, "text")
                        else line.get("end_time", 0)
                    )
                )
                for line in lyrics_val
            ]
        else:
            if isinstance(lyrics_val, str):
                lyrics_blocks = [
                    song_pb2.LyricBlock(text=line)
                    for line in lyrics_val.splitlines()
                    if line.strip()
                ]
            else:
                lyrics_blocks = []
        
        return song_pb2.LyricsResponse(
            lyrics = lyrics_blocks,
            source = lyrics_data.get("source", ""),
            hasTimestamps = has_timestamps
        )
    
    def related(self, request, context):
        video_id = request.id
        limit = int(request.limit)
        if limit == 0:
            limit = 5
        playlist = self.get_track(video_id)
        tracks = playlist.get("tracks", [])[1:limit + 1]
        
        related_songs = []
        for track in tracks:
            thumbnail_url = get_best_thumbnail(track.get("thumbnail") or [])

            artists_list = track.get("artists") or []
            artists_str = ",".join(
                artist.get("name", "")
                for artist in artists_list
                if artist and artist.get("name")
            )
            
            related_songs.append(
                song_pb2.RelatedSongs(
                    id=track.get("videoId", ""),
                    title=track.get("title", ""),
                    thumbnail=thumbnail_url,
                    artists=artists_str
                )
            )
            
        return song_pb2.RelatedResponse(
            related=related_songs
        )
    
    def credits(self, request, context):
        video_id = request.id
        playlist = self.get_track(video_id)
        tracks = playlist.get("tracks", [])

        if not tracks:
            return song_pb2.CreditsResponse(credits=[])

        watch_track = tracks[0]
        album_id = (watch_track.get("album") or {}).get("id", "")
        creditsId = None
        
        if album_id:
            try:
                album = self.get_album(album_id)
                album_tracks = album.get("tracks", [])
                
                track = next(
                    (t for t in album_tracks if t.get("videoId") == video_id),
                    None
                )
                
                if not track:
                    watch_title = watch_track.get("title", "").lower()
                    track = next(
                        (t for t in album_tracks if t.get("title", "").lower() == watch_title),
                        None
                    )
                
                if track:
                    creditsId = track.get("creditsBrowseId", "")
            except Exception:
                pass
            
        if not creditsId:
            creditsId = f"MPTC{video_id}"
            
        try:
            credits_data = self.get_credits(creditsId)
        except Exception:
            credits_data = {}
            
        if not isinstance(credits_data, dict):
            credits_data = {}
            
        credits = []

        for key, section in credits_data.items():
            if key == "other_sections":
                continue

            if not isinstance(section, dict):
                continue

            credits.append(
                song_pb2.Credit(
                    role=section.get("localized_title", key),
                    entities=[
                        song_pb2.CreditEntity(
                            name=name,
                            id=""
                        )
                        for name in section.get("data", [])
                    ]
                )
            )

        for section in credits_data.get("other_sections", []):
            credits.append(
                song_pb2.Credit(
                    role=section.get("localized_title", ""),
                    entities=[
                        song_pb2.CreditEntity(
                            name=name,
                            id=""
                        )
                        for name in section.get("data", [])
                    ]
                )
            )

        return song_pb2.CreditsResponse(
            credits=credits
        ) 