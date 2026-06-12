ARG DOCKER_HUB="docker.io"
ARG NODE_VERSION="18-alpine"

FROM $DOCKER_HUB/library/node:$NODE_VERSION AS build

WORKDIR /workspace

COPY . .

ARG NPM_REGISTRY="https://registry.npmjs.org"

RUN echo "registry = \"$NPM_REGISTRY\"" > .npmrc \
    && npm install \
    && node --max-old-space-size=2048 ./node_modules/.bin/ng build --configuration production

FROM $DOCKER_HUB/library/nginx:stable-alpine AS runtime

COPY --from=build /workspace/dist/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN chmod a+rwx /var/cache/nginx /var/run /var/log/nginx \
    && sed -i 's/^user/#user/' /etc/nginx/nginx.conf

EXPOSE 8080

USER nginx

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
    CMD wget -qO- http://localhost:8080 || exit 1
