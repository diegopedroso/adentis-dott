FROM golang:1.12

# Set the workspace that app will run
WORKDIR /app

# Copy everything from the current directory to the PWD
COPY app/ /app

# build the go code to a binary file
RUN go build hello-world.go  

# This container exposes port 8090 to the outside world
EXPOSE 8090

# Run the executable
ENTRYPOINT ["/app/hello-world"]
