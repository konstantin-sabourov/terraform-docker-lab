#!/bin/bash

echo "=== Infrastructure Health Check ==="
echo

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

check_container() {
    if docker ps --format '{{.Names}}' | grep -q "^$1$"; then
        echo -e "${GREEN}✓${NC} Container $1 is running"
        return 0
    else
        echo -e "${RED}✗${NC} Container $1 is NOT running"
        return 1
    fi
}

check_health() {
    status=$(docker inspect --format='{{.State.Health.Status}}' "$1" 2>/dev/null)
    if [ "$status" = "healthy" ]; then
        echo -e "${GREEN}✓${NC} Container $1 is healthy"
        return 0
    elif [ "$status" = "" ]; then
        echo -e "  Container $1 has no health check"
        return 0
    else
        echo -e "${RED}✗${NC} Container $1 health status: $status"
        return 1
    fi
}

test_port() {
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$1" | grep -q "200"; then
        echo -e "${GREEN}✓${NC} Port $1 is responding"
        return 0
    else
        echo -e "${RED}✗${NC} Port $1 is not responding"
        return 1
    fi
}

echo "1. Checking containers are running..."
check_container "postgres-db"
check_container "redis-cache"
check_container "webapp"
check_container "webapp2"
check_container "nginx-proxy"
echo

echo "2. Checking container health..."
check_health "postgres-db"
check_health "redis-cache"
echo

echo "3. Testing network connectivity..."
if docker exec webapp ping -c 1 database >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} webapp can reach database"
else
    echo -e "${RED}✗${NC} webapp cannot reach database"
fi

if docker exec webapp ping -c 1 cache >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} webapp can reach cache"
else
    echo -e "${RED}✗${NC} webapp cannot reach cache"
fi
echo

echo "4. Testing exposed ports..."
test_port "8080"
echo

echo "5. Testing database..."
if docker exec postgres-db psql -U appuser -d appdb -c "SELECT 1" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Database is accepting queries"
else
    echo -e "${RED}✗${NC} Database is not responding"
fi
echo

echo "6. Testing Redis..."
if docker exec redis-cache redis-cli ping | grep -q "PONG"; then
    echo -e "${GREEN}✓${NC} Redis is responding"
else
    echo -e "${RED}✗${NC} Redis is not responding"
fi
echo

echo "7. Testing service discovery..."
webapp_hosts=$(docker exec webapp getent hosts webapp 2>/dev/null | wc -l)
if [ "$webapp_hosts" -ge 2 ]; then
    echo -e "${GREEN}✓${NC} Load balancing: $webapp_hosts webapp instances found"
else
    echo -e "${RED}✗${NC} Load balancing: only $webapp_hosts webapp instance(s) found"
fi
echo

echo "=== Health Check Complete ==="