FROM nginx:latest
RUN apt update
RUN apt install -y curl
RUN rm /etc/nginx/conf.d/default.conf
HEALTHCHECK --retries=10 CMD curl -sk -XGET https://localhost
COPY nginx.conf /etc/nginx/conf.d
