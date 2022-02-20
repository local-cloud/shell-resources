FROM alpine:latest

ENV PATH=/usr/local/bin:/usr/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin
ENV SHELL_RESOURCES_TEST=1
ENV SVDIR=/etc/service

RUN apk add \
	bash \
	openssh-server \
	openssh-client \
	jq \
	findutils \
	sudo \
	curl  \
	nano \
	rsync \
	ncurses \
	runit

COPY tests/service /etc/service

ENTRYPOINT ["/sbin/runsvdir", "-P", "/etc/service"]
