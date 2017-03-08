FROM openjdk:8-alpine
MAINTAINER LasLabs Inc <support@laslabs.com>

ARG CONFLUENCE_VERSION=6.0.4

ENV CONFLUENCE_HOME=/var/atlassian/application-data/confluence
ENV CONFLUENCE_INSTALL=/opt/atlassian/confluence

ENV CONFLUENCE_DOWNLOAD_URI=https://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz

ENV RUN_USER=confluence
ENV RUN_GROUP=confluence

# Setup Confluence User & Group
RUN addgroup -S "${RUN_GROUP}" \
    && adduser -S -s /bin/false -G "${RUN_GROUP}" "${RUN_USER}"

# Install build deps
RUN apk add --no-cache --virtual .build-deps \
    curl \
    tar

# Create home, install, and conf dirs
RUN mkdir -p "${CONFLUENCE_HOME}" \
             "${CONFLUENCE_INSTALL}/conf"

# Download assets and extract to appropriate locations
RUN curl -Ls "${CONFLUENCE_DOWNLOAD_URI}" \
    | tar -xz --directory "${CONFLUENCE_INSTALL}" \
        --strip-components=1 --no-same-owner

# Setup permissions
RUN chmod -R 700 "${CONFLUENCE_HOME}" \
                 "${CONFLUENCE_INSTALL}/conf" \
                 "${CONFLUENCE_INSTALL}/temp" \
                 "${CONFLUENCE_INSTALL}/logs" \
                 "${CONFLUENCE_INSTALL}/work" \
    && chown -R ${RUN_USER}:${RUN_GROUP} "${CONFLUENCE_HOME}" \
                                         "${CONFLUENCE_INSTALL}/conf" \
                                         "${CONFLUENCE_INSTALL}/temp" \
                                         "${CONFLUENCE_INSTALL}/logs" \
                                         "${CONFLUENCE_INSTALL}/work"

# Update configs
RUN echo -e "\nconfluence.home=${CONFLUENCE_HOME}" >> "${CONFLUENCE_INSTALL}/confluence/WEB-INF/classes/confluence-init.properties" \
    && touch -d "@0" "${CONFLUENCE_INSTALL}/conf/server.xml"

# Remove build dependencies
RUN apk del .build-deps

# Switch from root
USER "${RUN_USER}":"${RUN_GROUP}"

# Expose ports
EXPOSE 8090
EXPOSE 8091

# Persist both the install and home dirs
VOLUME ["${CONFLUENCE_INSTALL}", "${CONFLUENCE_HOME}"]

# Set working directory to install directory
WORKDIR "${CONFLUENCE_INSTALL}"

# Run in foreground
CMD ["./bin/catalina.sh", "run"]

# Copy & set entrypoint for manual access
COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
