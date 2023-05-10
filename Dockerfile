FROM docker:dind

RUN apk add --no-cache git

COPY docker-buildx.sh /usr/local/bin/

CMD /usr/local/bin/docker-buildx.sh
