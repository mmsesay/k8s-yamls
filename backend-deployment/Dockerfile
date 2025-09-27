# Choose whatever you want, version >= 1.16
FROM golang:1.22-alpine

WORKDIR /app

RUN go install github.com/air-verse/air@latest
RUN go install github.com/pressly/goose/v3/cmd/goose@latest

COPY go.mod go.sum ./

RUN go mod download

COPY . .

# Build
RUN go build -o ./out/dist .

CMD ["air", "-c", ".air.toml", "./out/dist"]


#FROM golang:1.21.6 AS builder
#
#WORKDIR /usr/src/app
#
#COPY go.mod go.sum ./
#RUN go mod download
#RUN go mod verify
#
#
#COPY . .
#
#RUN go build -o backend ./cmd || (echo "Go build failed" && false)
#
#FROM golang:1.21.6
#WORKDIR /usr/src/app
#
#COPY --from=builder /usr/src/app/backend .
## COPY --from=builder /go/bin/goose /usr/local/bin/
## COPY --from=builder /usr/src/app/queries ./queries
#
#EXPOSE 8080
#
#CMD [ "./backend" ]