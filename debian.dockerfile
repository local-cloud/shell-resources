FROM debian:stable

ENV PATH=/usr/local/bin:/usr/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin
ENV SHELL_RESOURCES_TEST=1
ENV SVDIR=/etc/service

RUN apt-get update && apt-get install -y \
	bash \
	openssh-server \
	openssh-client \
	jq \
	findutils \
	sudo \
	curl  \
	nano \
	rsync \
	ncurses-bin \
	runit

ENTRYPOINT ["/usr/bin/runsvdir", "-P", "/etc/service"]
