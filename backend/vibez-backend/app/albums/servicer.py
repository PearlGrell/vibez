import grpc
from generated import album_pb2
from generated import album_pb2_grpc
from app.albums.service import AlbumService

class AlbumServicer(album_pb2_grpc.AlbumServicer):
    
    def __init__(self):
        self.albumService = AlbumService()
        
    def Album(self, request, context):
        return self.albumService.album(request, context)
