make build
make push

docker run -it --rm -e YII_INSTALL_TEMPLATE=true pvlg/yii2

docker run -it --rm -p 80:80 -e YII_APP_TEMPLATE=basic -e YII_INSTALL_TEMPLATE=true --name yii2 pvlg/yii2:php7.2-nginx
