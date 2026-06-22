from app.ytmusic_client import ytmusic
import grpc
from generated import album_pb2
from cachetools import TTLCache

class AlbumService:
    def __init__(self):
        self.album_cache = TTLCache(
            maxsize=10000,
            ttl=3600
        )

    def get_album(self, album_id):
        if album_id in self.album_cache:
            return self.album_cache[album_id]

        album = ytmusic.get_album(album_id)
        self.album_cache[album_id] = album
        return album

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

    def album(self, request, context):
        album_id = request.id
        try:
            album_data = self.get_album(album_id)
        except Exception as e:
            context.abort(
                grpc.StatusCode.NOT_FOUND,
                f"Album not found: {str(e)}"
            )

        if not album_data:
            context.abort(
                grpc.StatusCode.NOT_FOUND,
                "Album not found"
            )

        # Map artists
        artists = [
            album_pb2.AlbumArtist(
                id=artist.get("id") or "",
                name=artist.get("name", "")
            )
            for artist in album_data.get("artists", [])
            if artist
        ]

        # Map tracks
        tracks = []
        for track in album_data.get("tracks", []):
            track_artists = [
                album_pb2.AlbumArtist(
                    id=art.get("id") or "",
                    name=art.get("name", "")
                )
                for art in track.get("artists", [])
                if art
            ]
            
            thumbnails = track.get("thumbnails") or []
            track_thumbnail = self._get_best_thumbnail(thumbnails)

            tracks.append(
                album_pb2.AlbumTrack(
                    videoId=track.get("videoId") or "",
                    title=track.get("title", ""),
                    artists=track_artists,
                    album=track.get("album") or album_data.get("title") or "",
                    durationSeconds=track.get("duration_seconds") or 0,
                    thumbnail=track_thumbnail,
                    isExplicit=track.get("isExplicit", False),
                    trackNumber=track.get("trackNumber") or 0
                )
            )

        # Map other versions
        other_versions = []
        for version in album_data.get("other_versions", []):
            version_artists = [
                album_pb2.AlbumArtist(
                    id=art.get("id") or "",
                    name=art.get("name", "")
                )
                for art in version.get("artists", [])
                if art
            ]
            version_thumbnail = self._get_best_thumbnail(version.get("thumbnails"))
            other_versions.append(
                album_pb2.AlbumVersion(
                    id=version.get("browseId") or "",
                    title=version.get("title", ""),
                    artists=version_artists,
                    thumbnail=version_thumbnail,
                    isExplicit=version.get("isExplicit", False),
                    type=version.get("type", "")
                )
            )

        # Map related albums
        related_albums = []
        for related in album_data.get("related_recommendations", []):
            related_artists = [
                album_pb2.AlbumArtist(
                    id=art.get("id") or "",
                    name=art.get("name", "")
                )
                for art in related.get("artists", [])
                if art
            ]
            related_thumbnail = self._get_best_thumbnail(related.get("thumbnails"))
            related_albums.append(
                album_pb2.RelatedAlbum(
                    id=related.get("browseId") or "",
                    title=related.get("title", ""),
                    artists=related_artists,
                    thumbnail=related_thumbnail,
                    isExplicit=related.get("isExplicit", False),
                    type=related.get("type", "")
                )
            )

        album_thumbnail = self._get_best_thumbnail(album_data.get("thumbnails"))

        return album_pb2.AlbumResponse(
            id=album_id,
            title=album_data.get("title", ""),
            type=album_data.get("type", ""),
            thumbnail=album_thumbnail,
            isExplicit=album_data.get("isExplicit", False),
            description=album_data.get("description", ""),
            year=album_data.get("year", ""),
            artists=artists,
            trackCount=album_data.get("trackCount") or len(tracks),
            durationSeconds=album_data.get("duration_seconds") or 0,
            tracks=tracks,
            otherVersions=other_versions,
            relatedAlbums=related_albums
        )
