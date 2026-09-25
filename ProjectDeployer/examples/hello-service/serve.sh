#!/bin/sh

set -eu

while true; do
    printf 'HTTP/1.1 200 OK\r\nContent-Length: 3\r\nConnection: close\r\n\r\nok\n' | nc -l -p 8080
done
