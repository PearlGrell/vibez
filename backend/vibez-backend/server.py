"""The Python implementation of the gRPC route guide server."""

import logging
from concurrent import futures

import grpc
from grpc_reflection.v1alpha import reflection

import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), 'generated')))

from generated import search_pb2
from generated import search_pb2_grpc
from generated import song_pb2
from generated import song_pb2_grpc
from generated import album_pb2
from generated import album_pb2_grpc
from generated import artist_pb2
from generated import artist_pb2_grpc

from app.search.servicer import SearchServicer
from app.songs.servicer import SongServicer
from app.albums.servicer import AlbumServicer
from app.artists.servicer import ArtistServicer


def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    
    search_pb2_grpc.add_SearchServicer_to_server(
        SearchServicer(),
        server,
    )
    song_pb2_grpc.add_SongServicer_to_server(
        SongServicer(),
        server
    )
    album_pb2_grpc.add_AlbumServicer_to_server(
        AlbumServicer(),
        server
    )
    artist_pb2_grpc.add_ArtistServicer_to_server(
        ArtistServicer(),
        server
    )
    
    SERVICE_NAMES = (
        search_pb2.DESCRIPTOR.services_by_name["Search"].full_name,
        song_pb2.DESCRIPTOR.services_by_name["Song"].full_name,
        album_pb2.DESCRIPTOR.services_by_name["Album"].full_name,
        artist_pb2.DESCRIPTOR.services_by_name["Artist"].full_name,
        reflection.SERVICE_NAME,
    )

    reflection.enable_server_reflection(
        SERVICE_NAMES,
        server
    )
    
    listen_addr = "[::]:50051"
    server.add_insecure_port(listen_addr)
    print(f"Starting  server on {listen_addr}")
    server.start()
    server.wait_for_termination()


if __name__ == "__main__":
    logging.basicConfig()
    serve()
