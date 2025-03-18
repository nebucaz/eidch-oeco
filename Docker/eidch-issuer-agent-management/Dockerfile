# SPDX-FileCopyrightText: 2025 Swiss Confederation
#
# SPDX-License-Identifier: MIT

# Dockerfile used for github
FROM eclipse-temurin:21

RUN apt update && apt install -y dnsutils iputils-ping

RUN mkdir -p /app
WORKDIR /app

COPY eidch-issuer-agent-management/scripts/entrypoint.sh /app/entrypoint.sh

RUN chmod 766 $JAVA_HOME/lib/security/cacerts

ARG JAR_FILE=eidch-issuer-agent-management/target/*.jar
ADD ${JAR_FILE} /app/app.jar

RUN set -uxe && \
    chmod g=u /app/entrypoint.sh &&\
    chmod +x /app/entrypoint.sh

WORKDIR /app

USER 1001

ENTRYPOINT ["/app/entrypoint.sh","app.jar"]
