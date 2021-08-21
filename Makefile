APP = isucondition

all: $(APP)

$(APP): *.go
	GOOS=linux go build -o $(APP) ./webapp/go

scp: $(APP)
	scp ./$(APP) isu01:/home/isucon/$(APP)/webapp/go/$(APP)
	scp ./$(APP) isu02:/home/isucon/$(APP)/webapp/go/$(APP)
	scp ./$(APP) isu03:/home/isucon/$(APP)/webapp/go/$(APP)

scp-db:
	scp -r ./db isu01:/home/isucon/$(APP)/webapp/mysql
	scp -r ./db isu02:/home/isucon/$(APP)/webapp/mysql
	scp -r ./db isu03:/home/isucon/$(APP)/webapp/mysql

scp-env:
	scp ./env.sh isu01:/home/isucon/env.sh
	scp ./env.sh isu02:/home/isucon/env.sh
	scp ./env.sh isu03:/home/isucon/env.sh

restart:
	ssh isu01 "sudo systemctl restart $(APP).go.service"
	ssh isu02 "sudo systemctl restart $(APP).go.service"
	ssh isu03 "sudo systemctl restart $(APP).go.service"

stop:
	ssh isu01 "sudo systemctl stop $(APP).go.service"
	ssh isu02 "sudo systemctl stop $(APP).go.service"
	ssh isu03 "sudo systemctl stop $(APP).go.service"

start:
	ssh isu01 "sudo systemctl start $(APP).go.service"
	ssh isu02 "sudo systemctl start $(APP).go.service"
	ssh isu03 "sudo systemctl start $(APP).go.service"

deploy: $(APP) stop scp scp-db scp-env start

scp-nginx:
	ssh isu01 "sudo dd of=/etc/nginx/nginx.conf" < ./etc/nginx/nginx.conf

reload-nginx:
	ssh isu01 "sudo systemctl reload nginx.service"

deploy-nginx: scp-nginx reload-nginx

scp-mysql:
	ssh isu01 "sudo dd of=/etc/mysql/mysql.conf.d/mysqld.cnf" < ./etc/mysql/mysql.conf.d/mysqld.cnf
	ssh isu02 "sudo dd of=/etc/mysql/mysql.conf.d/mysqld.cnf" < ./etc/mysql/mysql.conf.d/mysqld.cnf
	ssh isu03 "sudo dd of=/etc/mysql/mysql.conf.d/mysqld.cnf" < ./etc/mysql/mysql.conf.d/mysqld.cnf

restart-mysql:
	ssh isu01 "sudo systemctl restart mysql.service"
	ssh isu02 "sudo systemctl restart mysql.service"
	ssh isu03 "sudo systemctl restart mysql.service"

deploy-mysql: scp-mysql restart-mysql
