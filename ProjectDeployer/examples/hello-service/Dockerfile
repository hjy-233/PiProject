FROM alpine:3.22

COPY serve.sh /usr/local/bin/serve
RUN chmod 755 /usr/local/bin/serve

USER 65534:65534
EXPOSE 8080
