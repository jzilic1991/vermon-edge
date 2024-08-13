import os
import sys
from fastapi_server import start_fastapi_server
from grpc_server import start_grpc_server

def main():
    server_type = os.getenv('SERVER_TYPE')

    if server_type == 'grpc':
        start_grpc_server()
    elif server_type == 'fastapi':
        start_fastapi_server()
    else:
        print(f"Unknown server type: {server_type}. Please choose 'grpc' or 'fastapi'.")
        sys.exit(1)

if __name__ == '__main__':
    main()

