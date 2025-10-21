#!/bin/bash
# Quick script to rebuild frontend assets
# Run this inside the container if CSS/JS files are missing

cd /home/frappe/frappe-bench

echo "Rebuilding frontend assets..."
bench build --production --app frappe
bench build --production --app erpnext  
bench build --production --app hrms

echo "Setting up asset symlinks..."
bench setup nginx --yes
bench setup socketio --yes

echo "Clearing cache..."
bench --site all clear-cache

echo "Verifying assets..."
ls -la /home/frappe/frappe-bench/sites/assets/ | head -20

echo "Assets rebuilt successfully!"
echo "Restart the container for changes to take effect."
