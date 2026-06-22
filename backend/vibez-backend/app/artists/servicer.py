import grpc
from generated import artist_pb2
from generated import artist_pb2_grpc
from app.artists.service import ArtistService

class ArtistServicer(artist_pb2_grpc.ArtistServicer):

    def __init__(self):
        self.artistService = ArtistService()

    def Artist(self, request, context):
        return self.artistService.artist(request, context)

    def ArtistSongs(self, request, context):
        return self.artistService.artist_songs(request, context)

    def ArtistAlbums(self, request, context):
        return self.artistService.artist_albums(request, context)
