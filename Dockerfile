FROM golang:1.20.14-alpine
RUN apk --no-cache add make gcc g++
WORKDIR /micro
COPY . .
RUN make micro && mv micro /usr/local/go/bin/micro

FROM alpine:latest
ENV USER=micro
ENV GROUPNAME=$USER
ARG UID=1001
ARG GID=1001
RUN apk --no-cache add make gcc g++
RUN apk --no-cache add git curl ca-certificates
COPY --from=0 /usr/local/go /usr/local/go
ENV PATH /usr/local/go/bin:/$USER/go/bin:$PATH
RUN addgroup --gid "$GID" "$GROUPNAME" \
    && adduser \
    --disabled-password \
    --gecos "" \
    --home "/micro" \
    --ingroup "$GROUPNAME" \
    --no-create-home \
    --uid "$UID" "$USER"
USER ${USER}
WORKDIR /micro
EXPOSE 8080
EXPOSE 8081
ENTRYPOINT ["/usr/local/go/bin/micro"]
CMD ["--help"]
