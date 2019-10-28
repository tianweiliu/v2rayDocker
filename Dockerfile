#
# Builder
#
FROM abiosoft/caddy:builder as builder

RUN go get -v github.com/abiosoft/parent
RUN ENABLE_TELEMETRY=false /bin/sh /usr/bin/builder.sh

#
# Final stage
#
FROM alpine:latest
# process wrapper
LABEL maintainer "sebs sebsclub@outlook.com"

# V2RAY
ARG TZ="Asia/Shanghai"

ENV TZ ${TZ}
ENV V2RAY_VERSION v4.20.0
ENV V2RAY_LOG_DIR /var/log/v2ray
ENV V2RAY_CONFIG_DIR /etc/v2ray/
# ENV V2RAY_DOWNLOAD_URL https://github.com/v2ray/v2ray-core/releases/download/${V2RAY_VERSION}/v2ray-linux-64.zip

RUN apk upgrade --update \
  && apk add \
  bash \
  tzdata \
  curl \
  && mkdir -p \ 
  ${V2RAY_LOG_DIR} \
  ${V2RAY_CONFIG_DIR} \
  && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
  && echo ${TZ} > /etc/timezone \
  && curl -Ls https://install.direct/go.sh | bash

# ADD entrypoint.sh /entrypoint.sh
WORKDIR /srv
# node
# install node 
RUN apk add --no-cache util-linux
RUN apk add --update nodejs nodejs-npm
COPY package.json /srv/package.json
RUN npm install
COPY v2ray.js /srv/v2ray.js

ARG version="1.0.3"
LABEL caddy_version="$version"

# Let's Encrypt Agreement
ENV ACME_AGREE="false"

# Telemetry Stats
ENV ENABLE_TELEMETRY="false"

RUN apk add --no-cache openssh-client git

# install caddy
COPY --from=builder /install/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins


VOLUME /root/.caddy /srv
# WORKDIR /srv

COPY Caddyfile /etc/Caddyfile
COPY index.html /srv/index.html
# COPY package.json /etc/package.json
# install process wrapper
COPY --from=builder /go/bin/parent /bin/parent
ADD caddy.sh /caddy.sh
EXPOSE 443 80
ENTRYPOINT ["/caddy.sh"]
# CMD ["--conf", "/etc/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE"]