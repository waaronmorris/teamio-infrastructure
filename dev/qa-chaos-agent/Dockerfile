FROM node:22-slim

WORKDIR /app

# Install deps first (layer cache)
COPY package.json package-lock.json* ./
RUN npm install

# Install Playwright Chromium + its OS deps
RUN npx playwright install --with-deps chromium

# Copy source
COPY tsconfig.json ./
COPY src/ src/

# Reports volume
RUN mkdir -p reports
VOLUME /app/reports

ENV HEADLESS=true
ENV NODE_ENV=production

ENTRYPOINT ["npx", "tsx", "src/agent.ts"]
