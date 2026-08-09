#!/usr/bin/env python3
"""
Temporary TCP Listener for Biometric Device Protocol Inspection
Listens on TCP 8005, logs client IP/port, timestamps, raw hexadecimal payload, and ASCII representation.
"""

import socket
import sys
import datetime
import os

HOST = '0.0.0.0'
PORT = 8005
LOG_FILE = '/var/log/biometric_raw.log'

def log_message(msg):
    timestamp = datetime.datetime.now(datetime.timezone.utc).isoformat()
    log_entry = f"[{timestamp}] {msg}\n"
    print(log_entry, end='', flush=True)
    try:
        with open(LOG_FILE, 'a', encoding='utf-8', errors='replace') as f:
            f.write(log_entry)
    except Exception as e:
        print(f"Failed to write to log file: {e}", file=sys.stderr)

def format_hex_ascii(data):
    hex_str = data.hex(' ')
    ascii_str = ''.join(chr(b) if 32 <= b <= 126 else '.' for b in data)
    return f"HEX ({len(data)} bytes): {hex_str}\nASCII: {ascii_str}"

def main():
    # Ensure log file directory exists
    log_dir = os.path.dirname(LOG_FILE)
    if log_dir and not os.path.exists(log_dir):
        os.makedirs(log_dir, exist_ok=True)

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server_sock:
        server_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            server_sock.bind((HOST, PORT))
            server_sock.listen(5)
            log_message(f"=== Biometric TCP Listener Started on {HOST}:{PORT} ===")
        except Exception as e:
            log_message(f"FATAL: Failed to bind to {HOST}:{PORT}: {e}")
            sys.exit(1)

        while True:
            try:
                client_sock, client_addr = server_sock.accept()
                log_message(f"CONNECT: Incoming TCP connection from {client_addr[0]}:{client_addr[1]}")
                
                with client_sock:
                    client_sock.settimeout(30.0) # 30s timeout per read
                    while True:
                        try:
                            data = client_sock.recv(4096)
                            if not data:
                                log_message(f"DISCONNECT: {client_addr[0]}:{client_addr[1]} closed connection.")
                                break
                            log_message(f"DATA FROM {client_addr[0]}:{client_addr[1]}:\n{format_hex_ascii(data)}")
                            
                            # ACK back if needed (optional standard HTTP 200 / ACK response)
                            # client_sock.sendall(b"OK")
                        except socket.timeout:
                            log_message(f"TIMEOUT: Connection idle timeout for {client_addr[0]}:{client_addr[1]}")
                            break
                        except Exception as e:
                            log_message(f"ERROR reading from {client_addr[0]}:{client_addr[1]}: {e}")
                            break
            except KeyboardInterrupt:
                log_message("=== Biometric TCP Listener Stopping (KeyboardInterrupt) ===")
                break
            except Exception as e:
                log_message(f"ERROR accepting connection: {e}")

if __name__ == '__main__':
    main()
