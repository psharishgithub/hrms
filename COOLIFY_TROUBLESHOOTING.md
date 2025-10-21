# Coolify Deployment Troubleshooting Guide

## Issue: Cannot Access Application via Domain or IP

### Updated Configuration
The configuration has been updated to:
- Use **ports 8000** (web) and **9000** (socketio) directly
- Simplified Dockerfile without Supervisor/Nginx
- Direct `bench start` command
- Proper health checks

### In Coolify - Port Configuration

1. **Go to your application settings**
2. **Ports & URLs section:**
   - Primary Port: `8000`
   - Add additional port: `9000` (for WebSocket/SocketIO)

3. **Domain Configuration:**
   - Set your domain to point to port `8000`
   - Example: `hrms.yourdomain.com` → Port `8000`

### Environment Variables Required

Make sure these are set in Coolify:

```bash
DB_PASSWORD=your_secure_password
SITE_NAME=hrms.yourdomain.com  # Use your actual domain!
ADMIN_PASSWORD=your_admin_password
DEVELOPER_MODE=0
```

**Important:** `SITE_NAME` MUST match your Coolify domain!

### Steps to Fix Access Issues

#### 1. Check Container Logs
In Coolify:
- Go to Logs tab
- Check the `hrms` service logs
- Look for:
  ```
  Starting Frappe Bench...
  Web server will be available on port 8000
  ```

#### 2. Verify Port Mapping
In Coolify application settings:
- Ensure port `8000` is exposed and mapped
- The domain should route to port `8000`

#### 3. Check Health Status
- Wait 2-3 minutes after deployment
- Container should show as "healthy"
- If unhealthy, check logs for errors

#### 4. Test Internal Connectivity
In Coolify terminal for `hrms` service:
```bash
curl http://localhost:8000
```
Should return HTML content, not connection refused.

#### 5. Verify Site Name
The `SITE_NAME` environment variable MUST match your domain:
```bash
# In Coolify terminal
cd /home/frappe/frappe-bench
bench --site all list
```
Should show your site name.

### Common Issues & Solutions

#### Issue: "Site does not exist"
**Solution:** 
- Delete the volume in Coolify
- Redeploy
- The entrypoint script will create the site automatically

#### Issue: "Connection Refused"
**Solution:**
1. Check if bench is actually running:
   ```bash
   ps aux | grep bench
   ```
2. Check if port 8000 is listening:
   ```bash
   netstat -tlnp | grep 8000
   ```

#### Issue: "502 Bad Gateway"
**Solution:**
- Application is starting but not ready yet
- Wait 2-3 minutes (first deployment can take 10-15 minutes)
- Check logs for "Bench is ready" or similar message

#### Issue: "DNS Resolution Failed"
**Solution:**
- Verify your domain DNS points to Coolify server IP
- Wait for DNS propagation (can take up to 24 hours)
- Try accessing via IP:8000 first to test if app works

#### Issue: Assets/CSS not loading
**Solution:**
- Make sure `SITE_NAME` matches your actual domain
- Rebuild bench:
  ```bash
  cd /home/frappe/frappe-bench
  bench build --app frappe
  bench build --app erpnext
  bench build --app hrms
  bench clear-cache
  ```

### Testing Checklist

After deployment, test in this order:

1. ✅ **Containers Running**
   - Check all 3 containers (hrms, mariadb, redis) are running
   
2. ✅ **Services Healthy**
   - Wait for health checks to pass (green indicator)
   
3. ✅ **Logs Clean**
   - No errors in logs
   - See "Bench is running" or "Starting Frappe"
   
4. ✅ **Internal Access**
   - Test `curl http://localhost:8000` in container terminal
   
5. ✅ **External Access**
   - Access via your domain
   - Should see Frappe login page

### Manual Deployment Test

To test locally before pushing to Coolify:

```powershell
# Build and start
docker-compose -f docker-compose.coolify.yml up --build

# Wait for initialization (10-15 minutes first time)
# Then access: http://localhost:8000
```

### Getting More Help

If still not working, collect this information:

1. **Container logs** (last 100 lines):
   ```bash
   docker logs <container-id> --tail 100
   ```

2. **Port status inside container**:
   ```bash
   docker exec <container-id> netstat -tlnp
   ```

3. **Bench status**:
   ```bash
   docker exec <container-id> bash -c "cd /home/frappe/frappe-bench && bench --site all list"
   ```

4. **Environment variables**:
   - Screenshot of Coolify environment variables (hide passwords!)

### Production Checklist

Before going live:

- [ ] Change `DB_PASSWORD` to strong password
- [ ] Change `ADMIN_PASSWORD` to strong password  
- [ ] Set `DEVELOPER_MODE=0`
- [ ] Configure SSL (Coolify auto-handles this)
- [ ] Set up backups
- [ ] Configure email settings
- [ ] Test login with Administrator account
- [ ] Enable 2FA for security

### Quick Reference

| Component | Port | Purpose |
|-----------|------|---------|
| Web Server | 8000 | Main application |
| SocketIO | 9000 | Real-time updates |
| MariaDB | 3306 | Database (internal) |
| Redis | 6379 | Cache/Queue (internal) |

### Support

- Coolify Docs: https://coolify.io/docs
- Frappe Forum: https://discuss.frappe.io
- GitHub Issues: https://github.com/frappe/hrms/issues
