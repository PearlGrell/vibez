"""The Python implementation of the gRPC route guide server."""

import logging
import signal
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
from app.stream_relay import start_stream_relay


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

    start_stream_relay(int(os.environ.get("STREAM_RELAY_PORT", "8080")))

    def handle_sigterm(*_):
        # Stop accepting new RPCs but give in-flight ones time to finish,
        # so Railway deploys/restarts don't kill requests mid-response.
        server.stop(grace=10)

    signal.signal(signal.SIGTERM, handle_sigterm)
    signal.signal(signal.SIGINT, handle_sigterm)
    server.wait_for_termination()


if __name__ == "__main__":
    logging.basicConfig()
    serve()
