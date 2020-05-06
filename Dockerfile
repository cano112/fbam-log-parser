FROM alpine:3.11.6

RUN apk add --no-cache bash sed

WORKDIR /
COPY log_parser.sh .
RUN chmod +x ./log_parser.sh
