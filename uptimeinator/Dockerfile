FROM golang:1.23-alpine3.21

WORKDIR /app
COPY main.go .
COPY go.mod .

RUN go build -o main main.go

# Install rclone
RUN apk add --no-cache rclone

CMD [ "/app/main" ]