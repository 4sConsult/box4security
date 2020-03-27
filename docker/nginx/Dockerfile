FROM nginx:latest
RUN rm /etc/nginx/conf.d/default.conf
HEALTHCHECK --interval=5m --timeout=3s CMD curl --fail http://localhost:443 || exit 1
COPY nginx.conf /etc/nginx/conf.d
