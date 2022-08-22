FROM redis:6.2.7 as base
COPY ./tls /tls
COPY ./docker-redis-entrypoint.sh docker-redis-entrypoint.sh
CMD [ "bash", "docker-redis-entrypoint.sh" ] 
