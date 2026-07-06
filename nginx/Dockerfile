FROM nginx:1.26-alpine

# Remove default configuration files
RUN rm -rf /etc/nginx/conf.d/*

# Install curl for health checking
RUN apk add --no-cache curl

# Expose HTTP and HTTPS ports
EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
