FROM golang:1.22.2-alpine3.19
WORKDIR /usr/src/app
COPY . .
RUN go mod download && go mod verify
RUN go build -v -o app main.go
CMD ["./app"]