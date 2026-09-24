FROM node:24-slim AS frontend
WORKDIR /app/frontend
ENV npm_config_audit=false npm_config_fund=false npm_config_update_notifier=false
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM eclipse-temurin:21-jdk AS backend
WORKDIR /app
COPY gradlew ./
COPY gradle/ gradle/
COPY build.gradle.kts settings.gradle.kts ./
RUN ./gradlew dependencies
COPY src src/
COPY --from=frontend /app/frontend/dist/ src/main/resources/static/
RUN ./gradlew bootJar

FROM eclipse-temurin:21-jre AS runtime
RUN addgroup --system appgroup
RUN adduser --system --no-create-home --shell /bin/sh --home /home/appuser --gecos "" --ingroup appgroup appuser
WORKDIR /app
COPY --from=backend /app/build/libs/*.jar app.jar
ENV JAVA_OPTS=""
EXPOSE 8080 9090
USER appuser
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
