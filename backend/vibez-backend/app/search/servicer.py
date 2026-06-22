from generated import search_pb2_grpc
from app.search.service import SearchService

class SearchServicer(search_pb2_grpc.SearchServicer):

    def __init__(self):
        self.service = SearchService()

    def Search(self, request, context):
        return self.service.search(
            request,
            context
        )