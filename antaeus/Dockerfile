FROM adoptopenjdk/openjdk11:latest

# Install dependencies
RUN apt-get update && apt-get install -y sqlite3

# Create homedir
RUN mkdir -p /home/pleo

# Switch to app homedir
WORKDIR /home/pleo

# Copy over source code
COPY . .

# When the container starts: build and test.
RUN ./gradlew build && ./gradlew test


FROM adoptopenjdk/openjdk11:latest

# Expose the app port.
EXPOSE 8000

# Create homedir
RUN mkdir /home/pleo

# Switch to app homedir
WORKDIR /home/pleo

# Copy over final build
COPY --from=0 /home/pleo .

# Run the app
CMD ./gradlew run
