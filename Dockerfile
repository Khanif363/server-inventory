FROM alpine:3.18


ARG ANSIBLE_VERSION=2.9.27
ENV ANSIBLE_VERSION=${ANSIBLE_VERSION}

# Install dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    openssh-client \
    sshpass \
    bash \
    && pip3 install --no-cache-dir ansible==${ANSIBLE_VERSION} \
    && rm -rf /tmp/* /var/cache/apk/*

# Copy ansible.cfg if needed
COPY ansible.cfg /etc/ansible/ansible.cfg

# Set working directory
WORKDIR /workspace

# Set default command
CMD ["/bin/bash"]