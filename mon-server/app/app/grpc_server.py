import os
import sys
import grpc
import demo_pb2
import demo_pb2_grpc
import logging
import datetime
from mon_server import MonServer
from state import app_state
from concurrent import futures
from util import ObjectiveProcName, construct_event_trace, evaluate_event_traces

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logging.info(f"gRPC version: {grpc.__version__}")

class CartService(demo_pb2_grpc.CartServiceServicer):
    def __init__(self, app_server_address):
        self.channel = grpc.insecure_channel(app_server_address)
        self.stub = demo_pb2_grpc.CartServiceStub(self.channel)
        self.app_state = app_state
        self.app_state.host = 1
        self.app_state.request_counter = 0
        self.app_state.req_fail_cnt = 0
        self.app_state.mon_server = MonServer(sys.argv[1], sys.argv[2])

    def AddItem(self, request, context):
        print(f"Forwarding AddItem request for user {request.user_id} to the app container.")
        start_time = datetime.datetime.now()
        try:
            response = self.stub.AddItem(request)
            response_time = (datetime.datetime.now() - start_time).total_seconds() * 1000
            traces = [construct_event_trace(ObjectiveProcName.RESPONSE, response_time)]
            evaluate_event_traces(traces)
            
            response_size = len(response.SerializeToString())
            # logging.info(f"AddItem response: {response}, size={response_size} bytes")
            return response
        except grpc.RpcError as e:
            context.set_code(e.code())
            context.set_details(e.details())
            return demo_pb2.Empty()

    def GetCart(self, request, context):
        print(f"Forwarding GetCart request for user {request.user_id} to the app container.")
        start_time = datetime.datetime.now()
        try:
            request_size = len(request.SerializeToString())
            # logging.info(f"Received GetCart request: user_id={request.user_id}, size={request_size} bytes")
            response = self.stub.GetCart(request)
            response_time = (datetime.datetime.now() - start_time).total_seconds() * 1000
            traces = [construct_event_trace(ObjectiveProcName.RESPONSE, response_time)]
            evaluate_event_traces(traces)
            
            response_size = len(response.SerializeToString())
            # logging.info(f"GetCart response: {response}, size={response_size} bytes")
            return response
        except grpc.RpcError as e:
            logging.error(f"GetCart RPC failed: code={e.code()}, details={e.details()}")
            context.set_code(e.code())
            context.set_details(e.details())
            return demo_pb2.Cart()

    def EmptyCart(self, request, context):
        print(f"Forwarding EmptyCart request for user {request.user_id} to the app container.")
        start_time = datetime.datetime.now()
        try:
            response = self.stub.EmptyCart(request)
            response_time = (datetime.datetime.now() - start_time).total_seconds() * 1000
            traces = [construct_event_trace(ObjectiveProcName.RESPONSE, response_time)]
            evaluate_event_traces(traces)
            
            response_size = len(response.SerializeToString())
            # logging.info(f"EmptyCart response: {response}, size={response_size} bytes")
            return response
        except grpc.RpcError as e:
            context.set_code(e.code())
            context.set_details(e.details())
            return demo_pb2.Empty()

def start_grpc_server():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers = 10))
    server_host = os.getenv("SERVER_HOST")
    server_port = os.getenv("SERVER_PORT")
    cart_service_addr = os.getenv("CART_SERVICE_ADDR")
    logging.info(f"Cart service address: {cart_service_addr}")
    cart_service = CartService(cart_service_addr)
    demo_pb2_grpc.add_CartServiceServicer_to_server(cart_service, server)
    insecure_port = f"0.0.0.0:{server_port}"
    logging.info(f"Insecure port: {insecure_port}")
    server.add_insecure_port(insecure_port)
    server.start()
    server.wait_for_termination()

