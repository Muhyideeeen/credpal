########################
# Build stage
########################
FROM node:20-alpine AS builder

WORKDIR /app

# Copy only dependency files first (better layer caching)
COPY package*.json ./

# Install only production dependencies
RUN npm ci --omit=dev

# Copy application source
COPY src ./src

########################
# Runtime stage
########################
FROM node:20-alpine

WORKDIR /app

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy built app from builder
COPY --from=builder /app /app

# Change ownership
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

# Healthcheck for container orchestrators
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Run app
CMD ["node", "src/index.js"]
