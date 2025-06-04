FROM alpine

RUN apk add --update --no-cache postgresql-client

RUN mkdir -p /init_scripts
WORKDIR /init_scripts
COPY init.sh ./

RUN chmod +x init.sh

CMD ["sh", "init.sh"]