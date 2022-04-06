# Build it
FROM golang AS builder

WORKDIR /payment

COPY /main.go .
COPY /go.mod .
COPY /go.sum .
# go get -d -v && 
RUN CGO_ENABLED=0 go build -installsuffix cgo -o payment .
# Final
FROM alpine:latest  as final

WORKDIR /payment
COPY --from=builder /payment/payment .

EXPOSE 9000

CMD ["./payment"]