FROM golang:1.23.2-alpine3.20 AS builder

RUN apk add git

WORKDIR /app

RUN git clone https://github.com/validaoxyz/hyperliquid-exporter .

RUN go mod download
RUN mkdir ./bin
RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o ./bin/hl_exporter ./cmd/hl-exporter

FROM ubuntu:24.04
WORKDIR /app
COPY --from=builder /app/bin/hl_exporter /bin/hl_exporter

RUN apt-get update && apt-get install -y ca-certificates curl wget

ENTRYPOINT ["/bin/hl_exporter"]
