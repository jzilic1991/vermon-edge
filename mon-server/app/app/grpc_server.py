import os
import grpc
import demo_pb2
import demo_pb2_grpc
from concurrent import futures

class CartService(demo_pb2_grpc.CartServiceServicer):
    def __init__(self, app_server_address):
        self.channel = grpc.insecure_channel(app_server_address)
        self.stub = demo_pb2_grpc.CartServiceStub(self.channel)

    def AddItem(self, request, context):
        print(f"Forwarding AddItem request for user {request.user_id} to the app container.")
        try:
            response = self.stub.AddItem(request)
            return response
        except grpc.RpcError as e:
            context.set_code(e.code())
            context.set_details(e.details())
            return demo_pb2.Empty()

    def GetCart(self, request, context):
        print(f"Forwarding GetCart request for user {request.user_id} to the app container.")
        try:
            response = self.stub.GetCart(request)
            return response
        except grpc.RpcError as e:
            context.set_code(e.code())
            context.set_details(e.details())
            return demo_pb2.Cart()

    def EmptyCart(self, request, context):
        print(f"Forwarding EmptyCart request for user {request.user_id} to the app container.")
        try:
            response = self.stub.EmptyCart(request)
            return response
        except grpc.RpcError as e:
            context.set_code(e.code())
            context.set_details(e.details())
            return demo_pb2.Empty()

def start_grpc_server():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers = 10))
    server_host = os.getenv("SERVER_HOST")
    server_port = os.getenv("SERVER_PORT")
    cart_service = CartService(f"http://{server_host}:{server_port}")
    demo_pb2_grpc.add_CartServiceServicer_to_server(cart_service, server)
    server.add_insecure_port(server_host + ":" + server_port)
    server.start()
    server.wait_for_termination()

