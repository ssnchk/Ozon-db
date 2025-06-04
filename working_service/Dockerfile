FROM golang:alpine as builder

WORKDIR /build

COPY . .

RUN go build -o bd_request_service_bin bd_request_service.go

FROM alpine

WORKDIR /app

COPY --from=builder /build/bd_request_service_bin .

RUN mkdir -p /app/sql

VOLUME /app/sql

CMD ["./bd_request_service_bin"]