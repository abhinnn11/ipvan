echo ==== start of docker logs =======
docker logs ipvanish-proxy
echo ==== end of docker logs =======
echo ---- curl -----
curl --proxy http://127.0.0.1:8888 https://api.ipify.org
echo ---- curl -----
