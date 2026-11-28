# Stage 1: build the React app
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .

# The API URL is baked into the JS at build time
ARG VITE_API_URL=http://localhost:5000
ENV VITE_API_URL=$VITE_API_URL
RUN npm run build

# Stage 2: serve the built files with nginx
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html

# Release tag (short commit SHA) from the image build workflow, so CD can check which build is live
ARG APP_VERSION=dev
RUN echo "$APP_VERSION" > /usr/share/nginx/html/version.txt

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ || exit 1