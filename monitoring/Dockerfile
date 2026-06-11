FROM golang:1.23.2-alpine3.20 AS builder

ARG EXPORTER_VERSION=v3.0.0

RUN apk add --no-cache git

WORKDIR /app

RUN git clone https://github.com/validaoxyz/hyperliquid-exporter.git .
RUN git checkout "${EXPORTER_VERSION}"

RUN go mod download
RUN mkdir ./bin
RUN GIT_COMMIT="$(git rev-parse --short HEAD)" && \
    GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build \
      -ldflags "-X github.com/validaoxyz/hyperliquid-exporter/internal/metrics.BuildVersion=${EXPORTER_VERSION} -X github.com/validaoxyz/hyperliquid-exporter/internal/metrics.BuildCommit=${GIT_COMMIT}" \
      -o ./bin/hl_exporter ./cmd/hl-exporter

FROM ubuntu:24.04
WORKDIR /app
COPY --from=builder /app/bin/hl_exporter /bin/hl_exporter

RUN apt-get update && apt-get install -y ca-certificates curl wget

ENTRYPOINT ["/bin/hl_exporter"]
