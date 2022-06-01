ARG REDIS_VER=6.2
ARG REDISEARCH_VER=v2.4.6
ARG REJSON_VER=v2.0.6
ARG RUST_VER=1.60.0

FROM rust:${RUST_VER} AS builderSearch

ARG REDISEARCH_VER

RUN apt clean && apt -y update && apt -y install --no-install-recommends \
    clang && rm -rf /var/lib/apt/lists/*

WORKDIR /

RUN git clone --recursive --depth 1 --branch ${REDISEARCH_VER} https://github.com/RediSearch/RediSearch.git

WORKDIR /RediSearch

RUN make setup

RUN make build

FROM rust:${RUST_VER} AS builderJSON

ARG REJSON_VER

RUN apt clean && apt -y update && apt -y install --no-install-recommends \
    clang && rm -rf /var/lib/apt/lists/*

WORKDIR /

RUN git clone --depth 1 --branch ${REJSON_VER} https://github.com/RedisJSON/RedisJSON.git

WORKDIR /RedisJSON

RUN cargo build --release

# run module in official redis
FROM redis:${REDIS_VER}
WORKDIR /data

RUN mkdir -p /usr/lib/redis/modules
COPY --from=builderSearch /RediSearch/bin/linux-arm64v8-release/search/redisearch.so /usr/lib/redis/modules
COPY --from=builderJSON /RedisJSON/target/release/librejson.so /usr/lib/redis/modules

EXPOSE 6379
CMD ["redis-server", "--loadmodule", "/usr/lib/redis/modules/redisearch.so", "--loadmodule", "/usr/lib/redis/modules/librejson.so"]
