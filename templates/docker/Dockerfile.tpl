# Dockerfile — {{PROJECT_NAME}}
# Image multi-stage : build complet puis runtime minimal (règle : docs/docker.md).
# Générique front/back : `npm run build` puis `npm run start` (scripts du package.json).

FROM node:{{NODE_VERSION}}-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM node:{{NODE_VERSION}}-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /app ./
EXPOSE 3000
CMD ["npm", "run", "start"]
