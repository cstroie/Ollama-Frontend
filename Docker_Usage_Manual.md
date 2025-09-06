# Docker Usage Manual for xsukax Ollama WebUI Chat Frontend

## Prerequisites

### System Requirements
- Docker Engine 20.10+ or Docker Desktop
- 512MB free RAM (minimum)
- 100MB free disk space
- Ollama installed and running on the host machine

### Repository Structure
After adding Docker support, your repository root will look like:
```
xsukax-Ollama-WebUI-Chat-Frontend/
├── index.html
├── README.md
├── LICENSE
├── Dockerfile
├── nginx.conf
├── default.conf
├── docker-compose.yml
├── .dockerignore
├── Makefile
├── Docker_quickstart.sh
└── Docker_quickstart.bat    (for Windows)
```

## Building the Docker Image

### Basic Build
```bash
# From the repository root directory
docker build -t xsukax-ollama-webui:latest .
```

### Build with Custom Tag
```bash
docker build -t xsukax-ollama-webui:1.0.0 .
```

### Build with No Cache (Fresh Build)
```bash
docker build --no-cache -t xsukax-ollama-webui:latest .
```

### Multi-platform Build
```bash
# For ARM64 and AMD64
docker buildx create --use
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t xsukax-ollama-webui:latest \
  --push .
```

### Verify Build
```bash
# Check if image was created
docker images | grep xsukax-ollama-webui
```

## Running the Container

### Basic Run Command
```bash
docker run -d \
  --name ollama-webui \
  -p 3553:80 \
  xsukax-ollama-webui:latest
```

### Run with Host Network Access (Linux)
```bash
docker run -d \
  --name ollama-webui \
  -p 3553:80 \
  --add-host=host.docker.internal:host-gateway \
  xsukax-ollama-webui:latest
```

### Run with Environment Variables
```bash
docker run -d \
  --name ollama-webui \
  -p 3553:80 \
  -e TZ=America/New_York \
  --restart unless-stopped \
  xsukax-ollama-webui:latest
```

### Run with Custom Network
```bash
# Create network
docker network create ollama-net

# Run container
docker run -d \
  --name ollama-webui \
  --network ollama-net \
  -p 3553:80 \
  xsukax-ollama-webui:latest
```

### Run with Live Reload (Development)
```bash
# Mount local index.html for development
docker run -d \
  --name ollama-webui-dev \
  -p 3553:80 \
  -v $(pwd)/index.html:/usr/share/nginx/html/index.html:ro \
  xsukax-ollama-webui:latest
```

## Docker Compose Setup

### Start with Docker Compose
```bash
# Start in detached mode
docker-compose up -d

# Start with build
docker-compose up -d --build

# Start and watch logs
docker-compose up
```

### Docker Compose Commands
```bash
# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Restart services
docker-compose restart

# View running services
docker-compose ps

# Execute command in container
docker-compose exec ollama-webui sh
```

## Advanced Configuration

### Custom Nginx Configuration
To modify Nginx settings, edit the configuration files before building:

1. **Adjust client body size** (in default.conf):
```nginx
client_max_body_size 50m;
```

2. **Change timeout settings** (in nginx.conf):
```nginx
keepalive_timeout 120;
```

3. **Rebuild the image**:
```bash
docker-compose up -d --build
```

### Environment-Specific Configurations
Create environment-specific compose files:

```bash
# Development
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Production
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Resource Limits
```bash
docker run -d \
  --name ollama-webui \
  -p 3553:80 \
  --memory="256m" \
  --cpus="0.5" \
  xsukax-ollama-webui:latest
```

## Networking and CORS

### Connecting to Ollama on Host

#### Configure Ollama
First, ensure Ollama accepts connections from the container:

```bash
# Linux/Mac - Start Ollama with CORS enabled
OLLAMA_ORIGINS=* ollama serve

# Windows - Set environment variable
set OLLAMA_ORIGINS=*
ollama serve

# Or set permanently in your shell profile
export OLLAMA_ORIGINS="*"
```

#### Docker Network Configuration

**Linux:**
```bash
docker run -d \
  --name ollama-webui \
  -p 3553:80 \
  --network="host" \
  xsukax-ollama-webui:latest
```

**macOS/Windows:**
```bash
docker run -d \
  --name ollama-webui \
  -p 3553:80 \
  --add-host=host.docker.internal:host-gateway \
  xsukax-ollama-webui:latest
```

### Testing Connectivity
```bash
# Test from inside container
docker exec -it ollama-webui sh
# Then inside container:
curl http://host.docker.internal:11434/api/tags
exit
```

## Troubleshooting

### Container Won't Start
```bash
# Check logs
docker logs ollama-webui

# Check detailed inspect
docker inspect ollama-webui

# Check port availability
netstat -tuln | grep 3553
# or
lsof -i :3553
```

### Connection to Ollama Fails
1. **Verify Ollama is running:**
```bash
curl http://localhost:11434/api/tags
```

2. **Check CORS configuration:**
```bash
# Should include OLLAMA_ORIGINS
env | grep OLLAMA
```

3. **Test from container:**
```bash
docker exec -it ollama-webui curl http://host.docker.internal:11434/api/tags
```

### Permission Issues
```bash
# Fix permissions (run as root temporarily)
docker exec -u root ollama-webui sh -c "chown -R nginx-user:nginx-user /usr/share/nginx/html"
```

### Debugging Mode
```bash
# Run interactively for debugging
docker run -it --rm \
  -p 3553:80 \
  --entrypoint sh \
  xsukax-ollama-webui:latest

# Inside container, manually start nginx
nginx -g "daemon off;"
```

### Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Port 3553 already in use | `docker ps` to find conflicting container, then `docker stop <container>` |
| Cannot connect to Ollama | Ensure `OLLAMA_ORIGINS=*` is set and Ollama is running |
| 404 Error on index.html | Verify index.html exists in repository root before building |
| Container exits immediately | Check logs with `docker logs ollama-webui` |
| Slow performance | Increase resource limits or check nginx cache settings |

## Security Considerations

### Running as Non-Root User
The container runs as `nginx-user` (UID 1001) by default for security.

### Read-Only Root Filesystem
For maximum security, run with read-only root:
```bash
docker run -d \
  --name ollama-webui \
  -p 3553:80 \
  --read-only \
  --tmpfs /var/run \
  --tmpfs /var/cache/nginx \
  --tmpfs /var/log/nginx \
  xsukax-ollama-webui:latest
```

### Network Isolation
```bash
# Create isolated network
docker network create --internal ollama-internal

# Run with isolation
docker run -d \
  --name ollama-webui \
  --network ollama-internal \
  -p 3553:80 \
  xsukax-ollama-webui:latest
```

### Security Scanning
```bash
# Scan with Docker Scout
docker scout cves xsukax-ollama-webui:latest

# Scan with Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image xsukax-ollama-webui:latest
```

## Maintenance and Updates

### Updating the Application
```bash
# Stop current container
docker-compose down

# Pull latest changes
git pull

# Rebuild and start
docker-compose up -d --build
```

### Backup and Restore
```bash
# Export image
docker save xsukax-ollama-webui:latest | gzip > ollama-webui-backup.tar.gz

# Import image
docker load < ollama-webui-backup.tar.gz
```

### Container Management
```bash
# View logs with timestamps
docker logs -t ollama-webui

# Monitor resource usage
docker stats ollama-webui

# Clean up stopped containers
docker container prune

# Clean up unused images
docker image prune -a
```

### Automated Updates with Watchtower
```bash
docker run -d \
  --name watchtower \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --cleanup \
  --interval 86400 \
  ollama-webui
```

## Quick Command Reference

```bash
# Build
docker build -t xsukax-ollama-webui:latest .

# Run (basic)
docker run -d --name ollama-webui -p 3553:80 xsukax-ollama-webui:latest

# Run (with host access)
docker run -d --name ollama-webui -p 3553:80 --add-host=host.docker.internal:host-gateway xsukax-ollama-webui:latest

# Docker Compose
docker-compose up -d                  # Start
docker-compose down                   # Stop
docker-compose logs -f                # Logs
docker-compose restart                # Restart
docker-compose up -d --build          # Rebuild and start

# Management
docker ps                             # List running
docker logs ollama-webui              # View logs
docker exec -it ollama-webui sh       # Shell access
docker restart ollama-webui           # Restart container
docker stop ollama-webui              # Stop container
docker rm ollama-webui                # Remove container

# Cleanup
docker system prune -a                # Clean everything
```

## Health Monitoring

### Check Health Status
```bash
# Via Docker
docker inspect --format='{{.State.Health.Status}}' ollama-webui

# Via HTTP
curl http://localhost:3553/health

# Via Docker Compose
docker-compose ps
```

### Monitor Logs
```bash
# Follow logs in real-time
docker-compose logs -f --tail=100

# Check nginx access logs
docker exec ollama-webui tail -f /var/log/nginx/access.log

# Check nginx error logs
docker exec ollama-webui tail -f /var/log/nginx/error.log
```

## Performance Tuning

### Nginx Optimization
Edit `nginx.conf` for better performance:
```nginx
worker_processes auto;
worker_connections 2048;
keepalive_timeout 120;
```

### Docker Resource Allocation
```yaml
# In docker-compose.yml
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 512M
    reservations:
      cpus: '0.5'
      memory: 256M
```

## Support and Resources

- **GitHub Repository**: https://github.com/xsukax/xsukax-Ollama-WebUI-Chat-Frontend
- **Ollama Documentation**: https://ollama.ai/docs
- **Docker Documentation**: https://docs.docker.com
- **Nginx Documentation**: https://nginx.org/en/docs/
- **Issues**: Report via GitHub Issues
- **Container Logs**: `docker logs ollama-webui`

## License

This Docker configuration is provided under the same GPL-3.0 license as the original xsukax Ollama WebUI project.