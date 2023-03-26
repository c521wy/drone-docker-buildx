FROM docker:dind

COPY docker-buildx.sh /usr/local/bin/

CMD /usr/local/bin/docker-buildx.sh
