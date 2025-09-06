# Multi-stage build for optimized image size
FROM alpine:3.19 AS builder

# Set working directory
WORKDIR /build

# Copy the index.html directly
COPY index.html .

# Production stage
FROM nginx:alpine3.19-slim

# Install necessary packages for runtime
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    curl \
    && rm -rf /var/cache/apk/*

# Create non-root user for nginx
RUN addgroup -g 1001 -S nginx-user && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx-user -g nginx-user nginx-user

# Remove default nginx configuration
RUN rm -rf /etc/nginx/conf.d/* && \
    rm -rf /usr/share/nginx/html/*

# Copy custom nginx configuration
COPY --chown=nginx-user:nginx-user nginx.conf /etc/nginx/nginx.conf
COPY --chown=nginx-user:nginx-user default.conf /etc/nginx/conf.d/default.conf

# Copy the application from builder stage
COPY --from=builder --chown=nginx-user:nginx-user /build/index.html /usr/share/nginx/html/

# Create necessary directories with proper permissions
RUN mkdir -p /var/cache/nginx /var/log/nginx /var/run && \
    chown -R nginx-user:nginx-user /var/cache/nginx /var/log/nginx /var/run /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:80/ || exit 1

# Expose port 80 (internal container port)
EXPOSE 80

# Set proper permissions for nginx pid file
RUN touch /var/run/nginx.pid && \
    chown nginx-user:nginx-user /var/run/nginx.pid

# Switch to non-root user
USER nginx-user

# Labels for better container management
LABEL maintainer="xsukax@xsukax.com" \
      version="1.0.0" \
      description="xsukax Ollama WebUI Chat Frontend - A modern web interface for Ollama AI models" \
      org.opencontainers.image.source="https://github.com/xsukax/xsukax-Ollama-WebUI-Chat-Frontend" \
      org.opencontainers.image.title="xsukax-ollama-webui" \
      org.opencontainers.image.description="Privacy-focused web interface for interacting with Ollama AI models" \
      org.opencontainers.image.vendor="xsukax" \
      org.opencontainers.image.licenses="GPL-3.0"

# Start nginx
CMD ["nginx", "-g", "daemon off;"]