# Frontend Dockerfile
FROM node:20.19-alpine

WORKDIR /app

# Install yarn
RUN npm install -g yarn --force

# Copy package files
COPY package.json yarn.lock* ./

# Install dependencies
RUN yarn install

# Copy source code
COPY . .

# Expose port
EXPOSE 3000

# Start command
CMD ["yarn", "dev"]