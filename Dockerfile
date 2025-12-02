# Build Stage
FROM golang:1.25-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o main main.go


# Run Stage
FROM alpine:3.19

# Install CA certificates (needed for HTTPS calls)
RUN apk --no-cache add ca-certificates

WORKDIR /app

# Copy built Go binary
COPY --from=builder /app/main .

# Copy supporting files
COPY app.env .
COPY start.sh .
COPY wait-for.sh .
COPY db/migration ./db/migration

EXPOSE 8080 9090

ENTRYPOINT ["/app/start.sh"]
CMD ["/app/main"]
