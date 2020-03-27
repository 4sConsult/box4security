FROM nginx:latest
RUN rm /etc/nginx/conf.d/default.conf
HEALTHCHECK --interval=1m --timeout=3s CMD curl --fail -k https://localhost || exit 1
COPY nginx.conf /etc/nginx/conf.d
