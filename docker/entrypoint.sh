#!/bin/bash
set -e

cd /home/frappe/frappe-bench

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
until mariadb -h"${DB_HOST:-mariadb}" -u"${DB_USER:-root}" -p"${DB_PASSWORD:-123}" -e "SELECT 1" &> /dev/null; do
  echo "MariaDB is unavailable - sleeping"
  sleep 2
done
echo "MariaDB is ready!"

# Wait for Redis to be ready
echo "Waiting for Redis to be ready..."
until redis-cli -h "${REDIS_HOST:-redis}" ping &> /dev/null; do
  echo "Redis is unavailable - sleeping"
  sleep 2
done
echo "Redis is ready!"

# Configure database and redis hosts
bench set-config -g db_host "${DB_HOST:-mariadb}"
bench set-config -g redis_cache "redis://${REDIS_HOST:-redis}:6379"
bench set-config -g redis_queue "redis://${REDIS_HOST:-redis}:6379"
bench set-config -g redis_socketio "redis://${REDIS_HOST:-redis}:6379"

# Disable redis and watch in Procfile (using external services)
sed -i '/^redis/d' ./Procfile
sed -i '/^watch/d' ./Procfile

# Check if site exists
SITE_NAME="${SITE_NAME:-hrms.localhost}"

if [ ! -d "sites/${SITE_NAME}" ]; then
  echo "Creating new site: ${SITE_NAME}"
  
  bench new-site "${SITE_NAME}" \
    --mariadb-root-password "${DB_PASSWORD:-123}" \
    --admin-password "${ADMIN_PASSWORD:-admin}" \
    --no-mariadb-socket \
    --force
  
  echo "Installing ERPNext..."
  bench --site "${SITE_NAME}" install-app erpnext
  
  echo "Installing HRMS..."
  bench --site "${SITE_NAME}" install-app hrms
  
  # Set as default site
  bench use "${SITE_NAME}"
  
  # Enable scheduler
  bench --site "${SITE_NAME}" enable-scheduler
  
  # Set configuration
  bench --site "${SITE_NAME}" set-config developer_mode "${DEVELOPER_MODE:-0}"
  bench --site "${SITE_NAME}" set-config allow_cors "*"
  
  # Build HRMS frontend apps (PWA and Roster) if they exist
  echo "Building HRMS frontend apps..."
  cd /home/frappe/frappe-bench/apps/hrms
  if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
    echo "Building HRMS PWA..."
    cd frontend && (yarn install --check-files && yarn build) || (npm install && npm run build)
    cd ..
  fi
  if [ -d "roster" ] && [ -f "roster/package.json" ]; then
    echo "Building HRMS Roster..."
    cd roster && (yarn install --check-files && yarn build) || (npm install && npm run build)
    cd ..
  fi
  cd /home/frappe/frappe-bench
  
  # Build Frappe/ERPNext/HRMS assets
  echo "Building Frappe assets..."
  bench build --app frappe
  
  echo "Building ERPNext assets..."
  bench build --app erpnext
  
  echo "Building HRMS assets..."
  bench build --app hrms
  
  # Setup assets symlinks for the site
  bench setup nginx --yes
  bench setup socketio --yes
  
  # Clear cache
  bench --site "${SITE_NAME}" clear-cache
  
  echo "Site ${SITE_NAME} created successfully!"
else
  echo "Site ${SITE_NAME} already exists, skipping creation..."
  bench use "${SITE_NAME}"
  
  # Build HRMS frontend apps if they exist
  echo "Building HRMS frontend apps..."
  cd /home/frappe/frappe-bench/apps/hrms
  if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
    echo "Building HRMS PWA..."
    cd frontend && (yarn install --check-files && yarn build) || (npm install && npm run build)
    cd ..
  fi
  if [ -d "roster" ] && [ -f "roster/package.json" ]; then
    echo "Building HRMS Roster..."
    cd roster && (yarn install --check-files && yarn build) || (npm install && npm run build)
    cd ..
  fi
  cd /home/frappe/frappe-bench
  
  # Rebuild Frappe/ERPNext/HRMS assets
  echo "Rebuilding assets..."
  bench build --app frappe
  bench build --app erpnext
  bench build --app hrms
  
  # Setup assets symlinks
  bench setup nginx --yes
  bench setup socketio --yes
  
  # Migrate if needed
  bench --site "${SITE_NAME}" migrate
  bench --site "${SITE_NAME}" clear-cache
fi

# Ensure assets are accessible
echo "Verifying assets..."
ls -la /home/frappe/frappe-bench/sites/assets/ | head -20

echo "Starting Frappe HRMS..."

# Execute the main command
exec "$@"
