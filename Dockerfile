FROM docker:dind

RUN apk add --no-cache git bash

COPY docker-buildx.sh /usr/local/bin/

CMD /usr/local/bin/docker-buildx.sh
