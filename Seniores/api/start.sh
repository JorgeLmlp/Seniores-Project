#!/bin/bash

# Seniores API - Docker Quick Start

echo "=== Starting Seniores API Stack ==="
echo ""

# Check if .env exists
if [ ! -f docker/.env ]; then
    echo "Error: docker/.env file not found. Copy docker/.env.example to docker/.env and update credentials."
    exit 1
fi

echo "Starting containers..."
docker compose -f docker/docker-compose.yml up -d

echo ""
echo "Waiting for services to be ready..."
sleep 5

echo ""
echo "=== Stack Status ==="
docker compose -f docker/docker-compose.yml ps

echo ""
echo "=== Access Points ==="
echo "Flask API: http://localhost:5001"
echo "MySQL:     localhost:3306"
echo ""
echo "Database credentials (from docker/.env):"
echo "  User: $(grep MYSQL_USER docker/.env | cut -d= -f2)"
echo "  Database: $(grep MYSQL_DATABASE docker/.env | cut -d= -f2)"
echo ""
echo "=== View Logs ==="
echo "docker compose -f docker/docker-compose.yml logs -f app"
echo ""
