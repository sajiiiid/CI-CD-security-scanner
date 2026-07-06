# Alpine Linux - a minimal 5MB base image
FROM alpine:3.21

# Install all the tools netscan.sh depends on
RUN apk add --no-cache bash nmap openssl curl bind-tools coreutils

# Copy the scanner script into the container
COPY netscan.sh /usr/local/bin/netscan.sh
RUN chmod +x /usr/local/bin/netscan.sh

# Set the scanner as the default command when the container starts
ENTRYPOINT ["/usr/local/bin/netscan.sh"]