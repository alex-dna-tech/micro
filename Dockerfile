FROM golang:1.20.14-alpine as builder
RUN apk --no-cache add make gcc g++
WORKDIR /micro
COPY . .
RUN make micro

FROM alpine:latest
ENV USER=micro
ENV GROUPNAME=$USER
ARG UID=1001
ARG GID=1001
RUN addgroup --gid "$GID" "$GROUPNAME" \
    && adduser \
    --disabled-password \
    --gecos "" \
    --home "/micro" \
    --ingroup "$GROUPNAME" \
    --no-create-home \
    --uid "$UID" "$USER"
ENV PATH /usr/local/go/bin:/$USER/go/bin:$PATH
RUN apk --no-cache add git make gcc g++ curl ca-certificates
COPY --from=builder /usr/local/go /usr/local/go
COPY --from=builder /micro/micro /usr/local/go/bin/
USER ${USER}
WORKDIR /micro
EXPOSE 8080
EXPOSE 8081
ENTRYPOINT ["/usr/local/go/bin/micro"]
CMD ["--help"]
