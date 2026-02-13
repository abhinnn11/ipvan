FROM alpine:3.20

# basic tools
RUN apk add --no-cache \
    openvpn \
    tinyproxy \
    iptables \
    bash \
    curl \
    unzip \
    ca-certificates

WORKDIR /app

# copy scripts
COPY root/ /

# download ipvanish configs
RUN mkdir -p /config \
    && wget -O /config/ipvanish.zip https://www.ipvanish.com/software/configs/configs.zip \
    && unzip /config/ipvanish.zip -d /config \
    && chmod +x /app/connect.sh \
    && chmod +x /app/healthcheck.sh \
    && chmod +x /app/tls-verify.sh

# tinyproxy setup
RUN sed -i 's/Allow /#Allow /g' /etc/tinyproxy/tinyproxy.conf \
 && sed -i 's/#DisableViaHeader/DisableViaHeader/g' /etc/tinyproxy/tinyproxy.conf \
 && sed -i 's/Port 8888/Port 8888/g' /etc/tinyproxy/tinyproxy.conf

ENV COUNTRY=NL
ENV USERNAME=""
ENV PASSWORD=""
ENV RANDOMIZE=true

EXPOSE 8888

HEALTHCHECK --interval=30s --timeout=5s \
 CMD /bin/sh /app/healthcheck.sh

ENTRYPOINT ["/app/connect.sh"]
