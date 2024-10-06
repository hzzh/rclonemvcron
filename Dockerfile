ARG BASE=alpine:latest
FROM ${BASE}

LABEL maintainer="henryz"

ARG ARCH=amd64
ENV MV_SRC=
ENV MV_DEST=
ENV CRON=
ENV FORCE_MV=
ENV UID=
ENV GID=

RUN apk --no-cache add dcron tzdata

COPY entrypoint.sh /
COPY mv.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD [""]
