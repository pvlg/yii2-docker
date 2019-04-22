PHP_VERSION=7.2
WEB_SERVER=nginx
build:
	docker build --build-arg PHP_INSTALL_VERSION=$(PHP_VERSION) --target $(WEB_SERVER) -t pvlg/yii2:php$(PHP_VERSION)-$(WEB_SERVER) src

push:
	docker push pvlg/yii2:php$(PHP_VERSION)-$(WEB_SERVER)

build-all:
	docker build --build-arg PHP_INSTALL_VERSION=5.6 --target nginx -t pvlg/yii2:php5.6-nginx src
	docker build --build-arg PHP_INSTALL_VERSION=7.0 --target nginx -t pvlg/yii2:php7.0-nginx src
	docker build --build-arg PHP_INSTALL_VERSION=7.1 --target nginx -t pvlg/yii2:php7.1-nginx src
	docker build --build-arg PHP_INSTALL_VERSION=7.2 --target nginx -t pvlg/yii2:php7.2-nginx src
	docker build --build-arg PHP_INSTALL_VERSION=7.3 --target nginx -t pvlg/yii2:php7.3-nginx src
	docker build --build-arg PHP_INSTALL_VERSION=5.6 --target apache -t pvlg/yii2:php5.6-apache src
	docker build --build-arg PHP_INSTALL_VERSION=7.0 --target apache -t pvlg/yii2:php7.0-apache src
	docker build --build-arg PHP_INSTALL_VERSION=7.1 --target apache -t pvlg/yii2:php7.1-apache src
	docker build --build-arg PHP_INSTALL_VERSION=7.2 --target apache -t pvlg/yii2:php7.2-apache src
	docker build --build-arg PHP_INSTALL_VERSION=7.3 --target apache -t pvlg/yii2:php7.3-apache src

push-all:
	docker push pvlg/yii2:php5.6-nginx
	docker push pvlg/yii2:php7.0-nginx
	docker push pvlg/yii2:php7.1-nginx
	docker push pvlg/yii2:php7.2-nginx
	docker push pvlg/yii2:php7.3-nginx
	docker push pvlg/yii2:php5.6-apache
	docker push pvlg/yii2:php7.0-apache
	docker push pvlg/yii2:php7.1-apache
	docker push pvlg/yii2:php7.2-apache
	docker push pvlg/yii2:php7.3-apache
