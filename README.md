# Dockerfile_php-fpm
docker build -t wozhangkun/php-fpm:7.0.33 .

docker run -d -v /var/www/html:/var/www/html --restart=unless-stopped --name php-fpm_7.0.33 wozhangkun/php-fpm:7.0.33
