FROM n8nio/runners:latest
USER root
RUN cd /opt/runners/task-runner-javascript && pnpm add moment uuid
RUN cd /opt/runners/task-runner-python && uv pip install pandas requests
COPY n8n-task-runners.json /etc/n8n-task-runners.json

USER runner