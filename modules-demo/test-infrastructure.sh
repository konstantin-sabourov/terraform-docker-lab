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

echo "3. Testing DNS resolution (network connectivity)..."
# Use getent instead of ping - it's built into the base image
if docker exec webapp getent hosts database >/dev/null 2>&1; then
    db_ip=$(docker exec webapp getent hosts database | awk '{print $1}')
    echo -e "${GREEN}✓${NC} webapp can resolve database ($db_ip)"
else
    echo -e "${RED}✗${NC} webapp cannot resolve database"
fi

if docker exec webapp getent hosts cache >/dev/null 2>&1; then
    cache_ip=$(docker exec webapp getent hosts cache | awk '{print $1}')
    echo -e "${GREEN}✓${NC} webapp can resolve cache ($cache_ip)"
else
    echo -e "${RED}✗${NC} webapp cannot resolve cache"
fi
echo

echo "4. Testing application connectivity to services..."
# Install psql and redis-cli temporarily for testing
echo "   Installing test tools in webapp (this may take a moment)..."
docker exec webapp bash -c "apt-get update -qq && apt-get install -y -qq postgresql-client redis-tools 2>&1 >/dev/null"

# Test database connection
if docker exec webapp psql "postgresql://appuser:secure_password_123@database:5432/appdb" -c "SELECT 1" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} webapp can connect to database"
else
    echo -e "${RED}✗${NC} webapp cannot connect to database"
fi

# Test Redis connection
if docker exec webapp redis-cli -h cache ping 2>/dev/null | grep -q "PONG"; then
    echo -e "${GREEN}✓${NC} webapp can connect to Redis cache"
else
    echo -e "${RED}✗${NC} webapp cannot connect to Redis cache"
fi
echo

echo "5. Testing exposed ports..."
test_port "8080"
echo

echo "6. Testing database directly..."
if docker exec postgres-db psql -U appuser -d appdb -c "SELECT 1" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Database is accepting queries"
else
    echo -e "${RED}✗${NC} Database is not responding"
fi
echo

echo "7. Testing Redis directly..."
if docker exec redis-cache redis-cli ping | grep -q "PONG"; then
    echo -e "${GREEN}✓${NC} Redis is responding"
else
    echo -e "${RED}✗${NC} Redis is not responding"
fi
echo

echo "8. Testing service discovery (load balancing)..."
webapp_count=$(docker exec nginx-proxy getent hosts webapp 2>/dev/null | wc -l)
if [ "$webapp_count" -ge 2 ]; then
    echo -e "${GREEN}✓${NC} Load balancing: $webapp_count webapp instances found"
    docker exec nginx-proxy getent hosts webapp | awk '{print "   - " $1}'
else
    echo -e "${RED}✗${NC} Load balancing: only $webapp_count webapp instance(s) found"
fi
echo

echo "9. Checking network topology..."
containers=$(docker network inspect app_network --format '{{range .Containers}}{{.Name}} {{end}}')
echo "   Containers on app_network: $containers"
echo

echo "=== Health Check Complete ==="