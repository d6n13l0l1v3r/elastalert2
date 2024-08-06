# Use an official Python runtime as a parent image
FROM python:3.12-slim

# Set environment variables
#ENV ELASTICSEARCH_HOST=elasticsearch
#ENV ELASTICSEARCH_PORT=9200
ENV ELASTALERT_CONFIG=/opt/elastalert/config/config.yaml
ENV ELASTALERT_RULES=/opt/elastalert/rules

# Set the working directory in the container
WORKDIR /opt/elastalert

# Copy the requirements file into the container
COPY requirements.txt ./

# Install dependencies
RUN apt update && apt -y upgrade && \
    apt -y install jq curl gcc libffi-dev gettext-base && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir -r requirements.txt && \
    apt -y remove gcc libffi-dev && \
    apt -y autoremove

# Copy the ElastAlert source code into the container
COPY . /opt/elastalert

# Create a script to initialize the ElastAlert index and run ElastAlert
RUN echo "#!/bin/sh" > /opt/elastalert/run.sh && \
    echo "set -e" >> /opt/elastalert/run.sh && \
    echo "envsubst < ${ELASTALERT_CONFIG} > /tmp/config.yaml" >> /opt/elastalert/run.sh && \
    echo "elastalert-create-index --index elastalert --old-index '' --config /tmp/config.yaml" >> /opt/elastalert/run.sh && \
    echo "elastalert --config /tmp/config.yaml --verbose" >> /opt/elastalert/run.sh && \
    chmod +x /opt/elastalert/run.sh

# Run ElastAlert
CMD ["/opt/elastalert/run.sh"]
