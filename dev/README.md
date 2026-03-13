# TeamIO Local Development Environment

This directory contains Docker Compose configuration to run the complete TeamIO stack locally.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)

## Services

| Service | Description | Port |
|---------|-------------|------|
| `db` | PostgreSQL 16 database | 5432 |
| `backend` | Rust/Axum API server | 8082 |
| `frontend` | React/Vite dev server | 3000 |
| `pgadmin` | Database admin UI (optional) | 5050 |

## Quick Start

### 1. Configure Environment

```bash
cd dev
cp .env.example .env
```

Edit `.env` if you need to change any defaults.

### 2. Start All Services

```bash
# Start the core stack (db, backend, frontend)
docker compose up -d

# Or start with logs visible
docker compose up
```

### 3. Access the Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8082/api
- **Swagger UI**: http://localhost:8082/swagger-ui
- **Health Check**: http://localhost:8082/health

### 4. Run Database Migrations

The backend will run migrations automatically on startup. If you need to run them manually:

```bash
docker compose exec backend /app/teamio-backend migrate
```

## Common Commands

### Start/Stop Services

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Stop and remove volumes (reset database)
docker compose down -v

# Restart a specific service
docker compose restart backend
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f frontend
```

### Database Access

```bash
# Connect to PostgreSQL via psql
docker compose exec db psql -U teamio -d teamio

# Or use pgAdmin (optional tool)
docker compose --profile tools up -d pgadmin
# Then access http://localhost:5050
```

### Rebuild Services

```bash
# Rebuild after code changes
docker compose build

# Rebuild specific service
docker compose build backend

# Rebuild and restart
docker compose up -d --build
```

## Development Workflow

### Backend Development

For active backend development, you may want to run the backend locally instead of in Docker:

```bash
# Start only db
docker compose up -d db

# Run backend locally
cd ../backend
DATABASE_URL=postgres://teamio:teamio_dev_password@localhost:5432/teamio cargo run
```

### Frontend Development

The frontend container mounts the source code, so changes should hot-reload. For faster development:

```bash
# Start only backend services
docker compose up -d db backend

# Run frontend locally
cd ../frontend-lovable
npm run dev
```

## Troubleshooting

### Port Already in Use

```bash
# Check what's using a port
lsof -i :8082

# Or change ports in docker-compose.yml
```

### Database Connection Issues

```bash
# Check if db is healthy
docker compose ps

# View db logs
docker compose logs db

# Reset database
docker compose down -v
docker compose up -d
```

### Backend Won't Start

```bash
# Check backend logs
docker compose logs backend

# Ensure db is ready
docker compose exec db pg_isready -U teamio
```

### Clear Everything and Start Fresh

```bash
docker compose down -v --rmi local
docker compose up -d --build
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Docker Network                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Frontend   │  │   Backend   │  │     PostgreSQL      │  │
│  │  (React)    │──│   (Rust)    │──│     Database        │  │
│  │  :3000      │  │   :8082     │  │     :5432           │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
         │                  │
         ▼                  ▼
   http://localhost:3000  http://localhost:8082/api
```

## Environment Variables

See `.env.example` for all available configuration options.

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_USER` | teamio | Database username |
| `POSTGRES_PASSWORD` | teamio_dev_password | Database password |
| `POSTGRES_DB` | teamio | Database name |
| `JWT_SECRET` | (dev value) | JWT signing secret |
| `RUST_LOG` | info | Backend log level |
| `VITE_API_URL` | http://localhost:8082/api | API URL for frontend |
