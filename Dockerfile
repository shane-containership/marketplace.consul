FROM library/consul:v0.6.4

MAINTAINER ContainerShip Developers <developers@containership.io>

ENV CONSUL_UI=true

RUN apk update
RUN apk add drill

ADD . /app
WORKDIR /app
CMD ./run.sh
