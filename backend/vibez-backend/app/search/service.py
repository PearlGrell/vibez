from app.ytmusic_client import ytmusic

import grpc
from generated import search_pb2
from generated import search_pb2_grpc


class SearchService():

    def search(self, request, context):
        query = request.query
        req_filter = request.filter
        limit = request.limit if request.limit > 0 else 20

        songs = []
        artists = []
        albums = []

        try:
            if req_filter == search_pb2.SONG:
                results = ytmusic.search(query=query, filter="songs", limit=limit)
                for item in results:
                    song = self._map_song(item)
                    if song:
                        songs.append(song)
            elif req_filter == search_pb2.ARTIST:
                results = ytmusic.search(query=query, filter="artists", limit=limit)
                for item in results:
                    artist = self._map_artist(item)
                    if artist:
                        artists.append(artist)
            elif req_filter == search_pb2.ALBUM:
                results = ytmusic.search(query=query, filter="albums", limit=limit)
                for item in results:
                    album = self._map_album(item)
                    if album:
                        albums.append(album)
            else:
                from concurrent.futures import ThreadPoolExecutor
                with ThreadPoolExecutor(max_workers=2) as executor:
                    future_all = executor.submit(lambda: ytmusic.search(query=query, limit=limit))
                    future_songs = executor.submit(lambda: ytmusic.search(query=query, filter="songs", limit=limit))

                    results_all = future_all.result()
                    results_songs = future_songs.result()

                for item in results_songs:
                    song = self._map_song(item)
                    if song:
                        songs.append(song)

                for item in results_all:
                    res_type = item.get("resultType")
                    if not res_type:
                        continue
                    res_type = res_type.lower()

                    if res_type == "artist":
                        artist = self._map_artist(item)
                        if artist:
                            artists.append(artist)
                    elif res_type == "album":
                        album = self._map_album(item)
                        if album:
                            albums.append(album)
        except Exception as e:
            context.abort(
                grpc.StatusCode.INTERNAL,
                str(e)
            )

        return search_pb2.SearchResult(
            songs=songs,
            artists=artists,
            albums=albums
        )

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

    def _map_song(self, item):
        video_id = item.get("videoId")
        if not video_id:
            return None

        album_val = item.get("album")
        album_name = ""
        if isinstance(album_val, dict):
            album_name = album_val.get("name", "")
        elif isinstance(album_val, str):
            album_name = album_val

        artists_data = item.get("artists") or []
        artists_names = []
        for artist in artists_data:
            if isinstance(artist, dict):
                name = artist.get("name")
                if name:
                    artists_names.append(name)
            elif isinstance(artist, str):
                artists_names.append(artist)
        artists_str = ", ".join(artists_names)

        thumbnails_data = item.get("thumbnails") or []
        thumbnail_url = self._get_best_thumbnail(thumbnails_data)

        return search_pb2.Song(
            id=video_id,
            title=item.get("title", ""),
            album=album_name,
            artists=artists_str,
            duration=item.get("duration_seconds") or 0,
            thumbnail=thumbnail_url,
        )

    def _map_artist(self, item):
        artist_name = item.get("artist") or item.get("name") or ""
        artist_id = item.get("browseId") or item.get("id") or ""

        if (not artist_name or not artist_id) and item.get("artists"):
            first_artist = item.get("artists")[0]
            if not artist_name:
                artist_name = first_artist.get("name", "")
            if not artist_id:
                artist_id = first_artist.get("id") or first_artist.get("browseId") or ""

        thumbnails_data = item.get("thumbnails") or []
        thumbnail_url = self._get_best_thumbnail(thumbnails_data)

        return search_pb2.Artist(
            id=artist_id,
            name=artist_name,
            thumbnail=thumbnail_url,
        )

    def _map_album(self, item):
        album_id = item.get("browseId") or item.get("playlistId") or ""
        
        album_artists_data = item.get("artists") or []
        artists_names = []
        for art in album_artists_data:
            if isinstance(art, dict):
                name = art.get("name")
                if name:
                    artists_names.append(name)
            elif isinstance(art, str):
                artists_names.append(art)
        
        artists_str = item.get("artist")
        if not artists_str and artists_names:
            artists_str = ", ".join(artists_names)

        album_thumbnails_data = item.get("thumbnails") or []
        thumbnail_url = self._get_best_thumbnail(album_thumbnails_data)

        return search_pb2.Album(
            id=album_id,
            title=item.get("title", ""),
            artists=artists_str or "",
            thumbnail=thumbnail_url,
            type=item.get("type", ""),
            year=item.get("year", ""),
        )

