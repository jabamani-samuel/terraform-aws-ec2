FROM alpine:3.12.0
RUN apk update \
 && apk add curl jq openjdk11 fontconfig ttf-dejavu aws-cli \
 && rm -rf /var/cache/apk/*
RUN apk add tzdata
ADD SimpleWeb.jar SimpleWeb.jar
ENTRYPOINT exec java -Dserver.port=8080 -jar SimpleWeb.jar