FROM nginx:alpine
WORKDIR /usr/share/nginx/html
RUN rm *.html
COPY build/ .
COPY ./nginx.conf /etc/nginx/conf/nginx.conf
