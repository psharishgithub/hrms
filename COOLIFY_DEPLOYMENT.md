# Coolify Deployment Guide for Frappe HRMS

This guide will help you deploy the Frappe HRMS application on Coolify.

## Prerequisites

1. A Coolify instance (self-hosted or cloud)
2. A domain name pointed to your Coolify server
3. Minimum server requirements:
   - 2 CPU cores
   - 4GB RAM (8GB recommended)
   - 20GB storage

## Deployment Steps

### 1. Connect Your Repository

1. Log in to your Coolify dashboard
2. Go to **Projects** → **New Project**
3. Choose **Git Repository**
4. Connect your Git repository (GitHub/GitLab/Bitbucket)
5. Select the `develop` branch

### 2. Configure the Application

1. **Application Type**: Select `Docker Compose`
2. **Docker Compose File**: Use `docker-compose.coolify.yml`
3. **Build Pack**: Docker Compose

### 3. Environment Variables

Set the following environment variables in Coolify:

**Required:**
```
DB_PASSWORD=your_secure_password_here
SITE_NAME=hrms.yourdomain.com
ADMIN_PASSWORD=your_admin_password
```

**Optional:**
```
DEVELOPER_MODE=0

# Port Configuration (change if needed)
APP_PORT=8000
SOCKETIO_PORT=9000

# Email Configuration
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=1
MAIL_LOGIN=your-email@gmail.com
MAIL_PASSWORD=your-app-password
```

### 4. Domain Configuration

1. Go to **Domains** section in your application
2. Add your domain: `hrms.yourdomain.com`
3. Enable **HTTPS** (Coolify will auto-provision SSL certificates)
4. **Port Mapping**: Set the port to match your `APP_PORT` environment variable (default: `8000`)
   - Main application: Uses `APP_PORT` (default 8000)
   - WebSocket/SocketIO: Uses `SOCKETIO_PORT` (default 9000)
   
**Note**: In Coolify, you typically only expose the main APP_PORT. The SOCKETIO_PORT is used internally for real-time features.

### 5. Persistent Storage

Coolify will automatically create and manage volumes for:
- `mariadb-data`: Database files
- `redis-data`: Redis persistence
- `hrms-sites`: Frappe site files
- `hrms-logs`: Application logs

### 6. Deploy

1. Click **Deploy** button
2. Wait for the build and deployment process (first deployment takes 10-15 minutes)
3. Monitor logs in the **Logs** tab

## Post-Deployment

### Accessing the Application

After successful deployment:
- Access your HRMS at: `https://hrms.yourdomain.com`
- Default credentials:
  - Username: `Administrator`
  - Password: `your_admin_password` (from env vars)

### Initial Setup

1. Log in with Administrator credentials
2. Complete the setup wizard
3. Configure your company details
4. Set up employees, departments, etc.

### Mobile App Access

The HRMS includes a PWA (Progressive Web App):
- Access via browser on mobile
- Install as app when prompted
- Supports offline functionality

## Maintenance

### Viewing Logs

In Coolify dashboard:
- Go to your application
- Click on **Logs** tab
- Select the service (hrms, mariadb, redis)

### Backup

Coolify automatically backs up volumes. You can also:

1. **Manual Database Backup:**
   ```bash
   # In Coolify's terminal for mariadb service
   mysqldump -u root -p frappe > backup.sql
   ```

2. **Manual Site Backup:**
   ```bash
   # In Coolify's terminal for hrms service
   bench --site hrms.yourdomain.com backup
   ```

### Updating the Application

1. Push changes to your repository
2. In Coolify, click **Redeploy**
3. Migrations will run automatically

### Scaling

To handle more load:

1. **Vertical Scaling**: Increase server resources in Coolify settings
2. **Horizontal Scaling**: Add more worker containers (edit docker-compose.coolify.yml)

## Troubleshooting

### Application won't start

1. Check logs in Coolify
2. Verify environment variables are set correctly
3. Ensure domain DNS is pointing to Coolify server

### Database connection issues

1. Check if mariadb container is healthy
2. Verify DB_PASSWORD matches in all services
3. Check logs: `docker logs <mariadb-container>`

### Site not accessible

1. **Verify domain configuration** in Coolify
2. **Check port mapping**: Ensure Coolify domain is pointing to your `APP_PORT` (default 8000)
3. **Check if SSL certificate was provisioned** (may take a few minutes)
4. **Verify DNS**: Ensure your domain DNS is pointing to Coolify server IP
5. **Check container logs** in Coolify for startup errors
6. **Test with IP**: Try accessing via `http://SERVER_IP:APP_PORT` first
7. **Check if site was created**: Look for "Site created successfully" in logs

### Performance issues

1. Increase server resources
2. Check Redis is running: `docker logs <redis-container>`
3. Monitor database performance
4. Consider enabling Redis cache optimization

## Advanced Configuration

### Custom Domain with Subdirectory

Edit `docker-compose.coolify.yml` and add:
```yaml
environment:
  - SITE_NAME=yourdomain.com/hrms
```

### Multi-Site Setup

To run multiple sites:
1. Deploy separate instances
2. Use different SITE_NAME for each
3. Configure reverse proxy in Coolify

### Email Configuration

For production, configure proper SMTP:
```bash
# In Coolify terminal for hrms service
bench --site hrms.yourdomain.com set-config mail_server "smtp.gmail.com"
bench --site hrms.yourdomain.com set-config mail_port 587
bench --site hrms.yourdomain.com set-config use_tls 1
bench --site hrms.yourdomain.com set-config mail_login "your-email@gmail.com"
bench --site hrms.yourdomain.com set-config mail_password "your-app-password"
```

## Security Recommendations

1. **Change default passwords** immediately after deployment
2. **Enable 2FA** for Administrator account
3. **Set up backups** regularly
4. **Keep updated**: Regularly redeploy with latest changes
5. **Monitor logs** for suspicious activity
6. **Use strong passwords** for DB_PASSWORD and ADMIN_PASSWORD
7. **Limit access**: Use Coolify's IP allowlist feature if needed

## Support

- **Frappe HR Documentation**: https://docs.frappe.io/hr
- **Community Forum**: https://discuss.frappe.io
- **GitHub Issues**: https://github.com/frappe/hrms/issues

## Notes

- First deployment takes 10-15 minutes due to building dependencies
- Subsequent deployments are faster (5-7 minutes)
- The application requires both HTTP (8000) and WebSocket (9000) ports
- Coolify handles SSL automatically via Let's Encrypt
- Database and Redis are isolated within the Docker network

---

**Version**: 1.0.0  
**Last Updated**: October 2025
