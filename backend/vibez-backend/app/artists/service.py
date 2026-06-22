from app.ytmusic_client import ytmusic
import grpc
from generated import artist_pb2
from cachetools import TTLCache

class ArtistService:
    def __init__(self):
        self.artist_cache = TTLCache(
            maxsize=10000,
            ttl=3600
        )
        self.failed_ids = TTLCache(
            maxsize=5000,
            ttl=1800
        )

    def get_artist(self, artist_id):
        if artist_id in self.failed_ids:
            return None

        if artist_id in self.artist_cache:
            return self.artist_cache[artist_id]

        try:
            artist = ytmusic.get_artist(artist_id)
        except KeyError:
            # Some channel IDs use a different page layout that ytmusicapi can't parse
            # Try with the channel ID prefixed as UCHP (artist handle format)
            alt_id = "UCHP" + artist_id[2:] if artist_id.startswith("UC") else None
            if alt_id:
                try:
                    artist = ytmusic.get_artist(alt_id)
                except Exception:
                    self.failed_ids[artist_id] = True
                    return None
            else:
                self.failed_ids[artist_id] = True
                return None

        self.artist_cache[artist_id] = artist
        return artist

    def _get_best_thumbnail(self, thumbnails):
        if not thumbnails:
            return ""
        try:
            best = max(thumbnails, key=lambda t: t.get("width", 0) * t.get("height", 0), default=None)
            if best:
                return best.get("url", "")
        except Exception:
            pass
        if isinstance(thumbnails, list) and thumbnails:
            return thumbnails[0].get("url", "") if isinstance(thumbnails[0], dict) else ""
        return ""

    def artist(self, request, context):
        artist_id = request.id
        try:
            artist_data = self.get_artist(artist_id)
        except Exception as e:
            context.abort(
                grpc.StatusCode.NOT_FOUND,
                f"Artist not found: {str(e)}"
            )
            return artist_pb2.ArtistResponse()

        if not artist_data:
            context.abort(
                grpc.StatusCode.NOT_FOUND,
                "Artist not found"
            )
            return artist_pb2.ArtistResponse()

        # Map songs
        songs = []
        songs_section = artist_data.get("songs") or {}
        for song in songs_section.get("results") or []:
            song_artists = [
                artist_pb2.ArtistSongArtist(
                    id=art.get("id") or "",
                    name=art.get("name", "")
                )
                for art in song.get("artists", [])
                if art
            ]
            album_val = song.get("album") or {}
            album_name = ""
            album_id = ""
            if isinstance(album_val, dict):
                album_name = album_val.get("name", "")
                album_id = album_val.get("id") or ""
            elif isinstance(album_val, str):
                album_name = album_val

            song_thumbnail = self._get_best_thumbnail(song.get("thumbnails"))

            duration = song.get("duration_seconds") or 0
            if not duration:
                dur_str = song.get("duration") or ""
                if dur_str and ":" in dur_str:
                    parts = dur_str.split(":")
                    try:
                        duration = int(parts[0]) * 60 + int(parts[1])
                    except ValueError:
                        duration = 0

            songs.append(
                artist_pb2.ArtistSong(
                    id=song.get("videoId") or "",
                    title=song.get("title", ""),
                    artists=song_artists,
                    album=album_name,
                    albumId=album_id,
                    thumbnail=song_thumbnail,
                    duration=duration,
                )
            )

        # Map albums
        albums = []
        albums_section = artist_data.get("albums") or {}
        for alb in albums_section.get("results") or []:
            alb_thumbnail = self._get_best_thumbnail(alb.get("thumbnails"))
            albums.append(
                artist_pb2.ArtistAlbum(
                    id=alb.get("browseId") or "",
                    title=alb.get("title", ""),
                    thumbnail=alb_thumbnail,
                    type=alb.get("type", "Album"),
                    year=alb.get("year", "")
                )
            )

        # Map singles
        singles = []
        singles_section = artist_data.get("singles") or {}
        for sgl in singles_section.get("results") or []:
            sgl_thumbnail = self._get_best_thumbnail(sgl.get("thumbnails"))
            singles.append(
                artist_pb2.ArtistSingle(
                    id=sgl.get("browseId") or "",
                    title=sgl.get("title", ""),
                    thumbnail=sgl_thumbnail,
                    type=sgl.get("type", "Single"),
                    year=sgl.get("year", "")
                )
            )

        # Map videos
        videos = []
        videos_section = artist_data.get("videos") or {}
        for vid in videos_section.get("results") or []:
            vid_thumbnail = self._get_best_thumbnail(vid.get("thumbnails"))
            videos.append(
                artist_pb2.ArtistVideo(
                    id=vid.get("videoId") or "",
                    title=vid.get("title", ""),
                    thumbnail=vid_thumbnail,
                    views=vid.get("views") or ""
                )
            )

        # Map related artists
        related_artists = []
        related_section = artist_data.get("related") or {}
        for rel in related_section.get("results") or []:
            rel_thumbnail = self._get_best_thumbnail(rel.get("thumbnails"))
            # related can have 'title' instead of 'name'
            rel_name = rel.get("name") or rel.get("title") or ""
            related_artists.append(
                artist_pb2.RelatedArtist(
                    id=rel.get("browseId") or "",
                    name=rel_name,
                    thumbnail=rel_thumbnail,
                    subscribers=rel.get("subscribers") or ""
                )
            )

        artist_thumbnail = self._get_best_thumbnail(artist_data.get("thumbnails"))

        songs_browse_id = songs_section.get("browseId") or ""
        albums_browse_id = albums_section.get("browseId") or ""
        albums_params = albums_section.get("params") or ""

        return artist_pb2.ArtistResponse(
            id=artist_id,
            name=artist_data.get("name", ""),
            description=artist_data.get("description", ""),
            views=artist_data.get("views") or "",
            subscribers=artist_data.get("subscribers") or "",
            monthlyListeners=artist_data.get("monthlyListeners") or "",
            thumbnail=artist_thumbnail,
            songs=songs,
            albums=albums,
            singles=singles,
            videos=videos,
            related=related_artists,
            songsBrowseId=songs_browse_id,
            albumsBrowseId=albums_browse_id,
            albumsParams=albums_params,
        )

    def _map_playlist_song(self, track):
        song_artists = [
            artist_pb2.ArtistSongArtist(
                id=art.get("id") or "",
                name=art.get("name", "")
            )
            for art in track.get("artists", [])
            if art
        ]
        album_val = track.get("album") or {}
        album_name = ""
        album_id = ""
        if isinstance(album_val, dict):
            album_name = album_val.get("name", "")
            album_id = album_val.get("id") or ""
        elif isinstance(album_val, str):
            album_name = album_val

        song_thumbnail = self._get_best_thumbnail(track.get("thumbnails"))

        duration = track.get("duration_seconds") or 0
        if not duration:
            dur_str = track.get("duration") or ""
            if dur_str and ":" in dur_str:
                parts = dur_str.split(":")
                try:
                    duration = int(parts[0]) * 60 + int(parts[1])
                except ValueError:
                    duration = 0

        return artist_pb2.ArtistSong(
            id=track.get("videoId") or "",
            title=track.get("title", ""),
            artists=song_artists,
            album=album_name,
            albumId=album_id,
            thumbnail=song_thumbnail,
            duration=duration,
        )

    def artist_songs(self, request, context):
        browse_id = request.browseId
        if not browse_id:
            context.abort(grpc.StatusCode.INVALID_ARGUMENT, "browseId is required")
            return artist_pb2.ArtistSongsResponse()

        try:
            playlist = ytmusic.get_playlist(browse_id, limit=50)
        except Exception as e:
            context.abort(grpc.StatusCode.NOT_FOUND, f"Failed to load songs: {str(e)}")
            return artist_pb2.ArtistSongsResponse()

        songs = []
        for track in playlist.get("tracks", []):
            song = self._map_playlist_song(track)
            if song.id:
                songs.append(song)

        return artist_pb2.ArtistSongsResponse(songs=songs)

    def artist_albums(self, request, context):
        channel_id = request.channelId
        browse_id = request.browseId
        params = request.params

        if not channel_id:
            context.abort(grpc.StatusCode.INVALID_ARGUMENT, "channelId is required")
            return artist_pb2.ArtistAlbumsResponse()

        results = []
        if params:
            try:
                results = ytmusic.get_artist_albums(channel_id, params=params)
            except (KeyError, Exception):
                # Some artists use musicShelfRenderer instead of musicCarouselShelfRenderer
                # Fall back to re-fetching artist data and returning what we have
                try:
                    artist_data = self.get_artist(channel_id)
                    if artist_data:
                        albums_section = artist_data.get("albums") or {}
                        results = albums_section.get("results") or []
                        singles_section = artist_data.get("singles") or {}
                        results = results + (singles_section.get("results") or [])
                except Exception:
                    pass

        albums = []
        for alb in results:
            alb_thumbnail = self._get_best_thumbnail(alb.get("thumbnails"))
            albums.append(
                artist_pb2.ArtistAlbum(
                    id=alb.get("browseId") or "",
                    title=alb.get("title", ""),
                    thumbnail=alb_thumbnail,
                    type=alb.get("type", "Album"),
                    year=alb.get("year", ""),
                )
            )

        return artist_pb2.ArtistAlbumsResponse(albums=albums)
