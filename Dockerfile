FROM node:lts-alpine AS manager
RUN apk add --no-cache libc6-compat tini
WORKDIR /usr/src/app

FROM manager AS build-dependencies
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

FROM manager AS builder
COPY --from=build-dependencies /usr/src/app/node_modules ./node_modules
COPY . .
RUN yarn build

FROM manager AS production-dependencies
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --production && yarn cache clean

FROM manager AS production
ENV NODE_ENV production
COPY --from=production-dependencies --chown=node:node /usr/src/app/node_modules ./node_modules
COPY --from=builder --chown=node:node /usr/src/app/dist ./dist
COPY --from=builder --chown=node:node /usr/src/app/package.json ./package.json

USER node
EXPOSE 8000
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "dist/main.js"]
