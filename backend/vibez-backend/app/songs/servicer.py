import grpc
from generated import song_pb2
from generated import song_pb2_grpc
from app.songs.service import SongService

class SongServicer(song_pb2_grpc.SongServicer):
    
    def __init__(self):
        self.songService = SongService()
        
    def Song(self,request,context):
        return self.songService.song(request, context)
    
    def Audio(self,request,context):
        return self.songService.audio(request,context)
    
    def Lyrics(self,request,context):
        return self.songService.lyrics(request,context)
    
    def Related(self,request,context):
        return self.songService.related(request,context)
    
    def Credits(self,request,context):
        return self.songService.credits(request,context)