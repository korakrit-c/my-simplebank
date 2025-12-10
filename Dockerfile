FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o simplebank .

FROM gcr.io/distroless/base-debian12
WORKDIR /app
COPY --from=builder /app/simplebank /app/
COPY app.env /app/app.env
EXPOSE 8080
CMD ["/app/simplebank"]
