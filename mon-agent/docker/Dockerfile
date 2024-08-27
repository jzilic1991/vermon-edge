# Use an official Python runtime as a parent image
FROM python:3.7.9-slim-buster

# Install necessary system dependencies
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    curl \
    libglu1 \
    libaio1 \
    libaio-dev \
    libjpeg62 \
    libopenjp2-7 \
    libtiff5 \
    libatlas-base-dev \
    iperf3 \
    net-tools \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Allow Pi Wheels for ARM architecture (remove if not needed)
RUN echo "[global]\nextra-index-url=https://www.piwheels.org/simple" >> /etc/pip.conf

# Copy the requirements.txt first to leverage Docker cache
COPY docker/requirements.txt /app/requirements.txt
WORKDIR /app

# Upgrade pip and install required Python packages
RUN pip3 install --upgrade pip && pip3 install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY app/ /app

# Expose the application port
EXPOSE 8000

# Set the entry point to run your application
ENTRYPOINT [ "python3", "-u", "mon-agent.py" ]
