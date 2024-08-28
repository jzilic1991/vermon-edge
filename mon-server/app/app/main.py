import os
import sys
from obj_fastapi_server import start_obj_fastapi_server
from req_fastapi_server import start_req_fastapi_server
from grpc_server import start_grpc_server

def main():
    server_type = os.getenv('SERVER_TYPE')

    if server_type == 'grpc':
        start_grpc_server()
    elif server_type == 'fastapi':
        if sys.argv[1] == "obj":
            start_obj_fastapi_server()
        elif sys.argv[1] == "req":
            start_req_fastapi_server()
        else:
            print(f"Unknown passed argument: {sys.argv[1]}, Please provide 'obj' or 'req' for correct verifier instantiation.")
            sys.exit(1)
    else:
        print(f"Unknown server type: {server_type}. Please choose 'grpc' or 'fastapi'.")
        sys.exit(1)

if __name__ == '__main__':
    main()
