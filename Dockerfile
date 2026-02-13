FROM alpine:3.20

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
COPY root/ /app/

# copy LOCAL ipvanish configs (instead of wget)
COPY configs.zip /config/configs.zip

# extract configs
RUN mkdir -p /config \
    && unzip /config/configs.zip -d /config \
    && chmod +x /app/connect.sh \
    && chmod +x /app/healthcheck.sh \
    && chmod +x /app/tls-verify.sh

# (old online download — disabled)
# RUN wget https://www.ipvanish.com/software/configs/configs.zip -P config/

# tinyproxy adjustments
RUN sed -i 's/Allow /#Allow /g' /etc/tinyproxy/tinyproxy.conf \
 && sed -i 's/#DisableViaHeader/DisableViaHeader/g' /etc/tinyproxy/tinyproxy.conf



EXPOSE 8888

HEALTHCHECK --interval=30s --timeout=5s \
 CMD /bin/sh /app/healthcheck.sh

ENTRYPOINT ["/app/connect.sh"]
