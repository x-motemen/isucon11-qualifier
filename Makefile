APP = isucondition

all: $(APP)

$(APP): webapp/go/*.go
	GOOS=linux GOARCH=amd64 go build -o $(APP) ./webapp/go

scp: $(APP)
	scp ./$(APP) isu01:/home/isucon/webapp/go/$(APP) & \
	scp ./$(APP) isu02:/home/isucon/webapp/go/$(APP) & \
	scp ./$(APP) isu03:/home/isucon/webapp/go/$(APP) & \
	wait

scp-db:
	scp -r ./webapp/sql isu01:/home/isucon/webapp & \
	scp -r ./webapp/sql isu02:/home/isucon/webapp & \
	scp -r ./webapp/sql isu03:/home/isucon/webapp & \
	wait

scp-env:
	scp ./env.sh isu01:/home/isucon/env.sh
	scp ./env.sh isu02:/home/isucon/env.sh
	scp ./env.sh isu03:/home/isucon/env.sh

restart:
	ssh isu01 "sudo systemctl restart $(APP).go.service" & \
	ssh isu02 "sudo systemctl restart $(APP).go.service" & \
	ssh isu03 "sudo systemctl restart $(APP).go.service" & \
	wait

stop:
	ssh isu01 "sudo systemctl stop $(APP).go.service" & \
	ssh isu02 "sudo systemctl stop $(APP).go.service" & \
	ssh isu03 "sudo systemctl stop $(APP).go.service" & \
	wait

start:
	ssh isu01 "sudo systemctl start $(APP).go.service" & \
	ssh isu02 "sudo systemctl start $(APP).go.service" & \
	ssh isu03 "sudo systemctl start $(APP).go.service" & \
	wait

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
