#!/bin/bash

# Build the user-service application using Gradle
./gradlew bootJar

# Run the user-service container
docker run -d \
  --name quickbite-user \
  -p 8081:8081 \
  -v $(pwd)/build/libs:/app \
  -w /app \
  --add-host=host.docker.internal:host-gateway \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://host.docker.internal:5432/postgres \
  -e SPRING_DATASOURCE_USERNAME=postgres \
  -e SPRING_DATASOURCE_PASSWORD=secret \
  eclipse-temurin:17-jre-alpine \
  java -jar user-service-0.0.1-SNAPSHOT.jar
