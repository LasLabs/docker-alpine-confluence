FROM openjdk:8-alpine
MAINTAINER LasLabs Inc <support@laslabs.com>

ARG CONFLUENCE_VERSION=6.2.3

ARG CONFLUENCE_HOME=/var/atlassian/application-data/confluence
ARG CONFLUENCE_INSTALL=/opt/atlassian/confluence

ARG CONFLUENCE_DOWNLOAD_URI=https://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz

ARG RUN_USER=confluence
ARG RUN_GROUP=confluence

ENV LC_ALL=C

# Setup Confluence User & Group
RUN addgroup -S "${RUN_GROUP}" \
    && adduser -S -s /bin/false -G "${RUN_GROUP}" "${RUN_USER}" \
# Install build deps
    && apk add --no-cache --virtual .build-deps \
        bash \
        curl \
        fontconfig \
        tar \
        ttf-dejavu \
# Create home, install, and conf dirs
    && mkdir -p "${CONFLUENCE_HOME}" \
                 "${CONFLUENCE_INSTALL}/conf" \
# Download assets and extract to appropriate locations
    && curl -Ls "${CONFLUENCE_DOWNLOAD_URI}" \
        | tar -xz --directory "${CONFLUENCE_INSTALL}" \
            --strip-components=1 --no-same-owner \
# Setup permissions
    && chmod -R 700 "${CONFLUENCE_HOME}" \
                     "${CONFLUENCE_INSTALL}/conf" \
                     "${CONFLUENCE_INSTALL}/temp" \
                     "${CONFLUENCE_INSTALL}/logs" \
                     "${CONFLUENCE_INSTALL}/work" \
    && chown -R ${RUN_USER}:${RUN_GROUP} "${CONFLUENCE_HOME}" \
                                         "${CONFLUENCE_INSTALL}/conf" \
                                         "${CONFLUENCE_INSTALL}/temp" \
                                         "${CONFLUENCE_INSTALL}/logs" \
                                         "${CONFLUENCE_INSTALL}/work" \
# Update configs
    && echo -e "\nconfluence.home=${CONFLUENCE_HOME}" \
        >> "${CONFLUENCE_INSTALL}/confluence/WEB-INF/classes/confluence-init.properties" \
    && touch -d "@0" "${CONFLUENCE_INSTALL}/conf/server.xml" \
# Remove build dependencies
    && apk del .build-deps

# Switch from root
USER "${RUN_USER}":"${RUN_GROUP}"

# Expose ports
EXPOSE 8090
EXPOSE 8091

# Persist both the install and home dirs + JRE security folder (cacerts)
VOLUME ["${CONFLUENCE_INSTALL}", "${CONFLUENCE_HOME}", "${JAVA_HOME}/jre/lib/security/"]]

# Set working directory to install directory
WORKDIR "${CONFLUENCE_INSTALL}"

# Run in foreground
CMD ["./bin/catalina.sh", "run"]

# Copy & set entrypoint for manual access
COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

# Metadata
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Confluence - Alpine" \
      org.label-schema.description="Provides a Docker image for Confluence on Alpine Linux." \
      org.label-schema.url="https://laslabs.com/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/LasLabs/docker-alpine-confluence" \
      org.label-schema.vendor="LasLabs Inc." \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"
