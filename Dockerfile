FROM python:3.13-alpine3.24
LABEL org.opencontainers.image.source=https://github.com/kiwix/seeder

RUN apk add --no-cache dumb-init

COPY README.md /src/
COPY pyproject.toml README.md tasks.py /src/
COPY src/kiwixseeder/__about__.py /src/src/kiwixseeder/__about__.py
# install python dependencies
RUN pip install --no-cache-dir --break-system-packages /src/

COPY src/ /src/src
RUN set -e \
    && pip install --break-system-packages /src/ \
    && kiwix-seeder --help

VOLUME /data
WORKDIR /data

ENTRYPOINT ["/usr/bin/dumb-init"]
CMD ["kiwix-seeder"]
