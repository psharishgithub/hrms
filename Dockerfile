# Multi-stage Dockerfile for Frappe HRMS
FROM frappe/bench:latest as builder

USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    vim \
    nano \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

USER frappe

# Set working directory
WORKDIR /home/frappe

# Set environment variables
ENV FRAPPE_BRANCH=version-15
ENV ERPNEXT_BRANCH=version-15
ENV HRMS_BRANCH=develop

# Initialize bench
RUN bench init --skip-redis-config-generation --frappe-branch ${FRAPPE_BRANCH} frappe-bench

WORKDIR /home/frappe/frappe-bench

# Get apps
RUN bench get-app --branch ${ERPNEXT_BRANCH} erpnext && \
    bench get-app --branch ${HRMS_BRANCH} hrms

# Build frontend assets
RUN bench build --app frappe && \
    bench build --app erpnext && \
    bench build --app hrms

# Production stage
FROM frappe/bench:latest

USER root

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    supervisor \
    nginx \
    && rm -rf /var/lib/apt/lists/*

USER frappe

WORKDIR /home/frappe

# Copy bench from builder
COPY --chown=frappe:frappe --from=builder /home/frappe/frappe-bench /home/frappe/frappe-bench

WORKDIR /home/frappe/frappe-bench

# Copy custom configs
COPY --chown=frappe:frappe docker/supervisor.conf /etc/supervisor/conf.d/frappe.conf
COPY --chown=frappe:frappe docker/nginx.conf /etc/nginx/nginx.conf
COPY --chown=frappe:frappe docker/entrypoint.sh /usr/local/bin/entrypoint.sh

USER root
RUN chmod +x /usr/local/bin/entrypoint.sh

USER frappe

# Expose ports
EXPOSE 8000 9000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD bench --site all list || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
