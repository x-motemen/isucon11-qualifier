APP = isucondition

all: $(APP)

$(APP): webapp/go/*.go
	GOOS=linux GOARCH=amd64 go build -o $(APP) ./webapp/go

scp: $(APP)
	scp ./$(APP) isu01:/home/isucon/webapp/go/$(APP) & \
	scp ./$(APP) isu02:/home/isucon/webapp/go/$(APP) & \
	scp ./$(APP) isu03:/home/isucon/webapp/go/$(APP) & \
	wait

scp-sql:
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

deploy: $(APP) stop scp scp-sql scp-env rotate-nginx start

scp-nginx:
	ssh isu01 "sudo dd of=/etc/nginx/nginx.conf" < ./etc/nginx/nginx.conf
	ssh isu01 "sudo dd of=/etc/nginx/sites-available/isucondition.conf" < ./etc/nginx/sites-available/isucondition.conf

reload-nginx:
	ssh isu01 "sudo systemctl reload nginx.service"

rotate-nginx:
	ssh isu01 sudo sh -c 'test -f /var/log/nginx/access_log.ltsv && mv -f /var/log/nginx/access_log.ltsv /var/log/nginx/access_log.ltsv.old || true'
	ssh isu01 'sudo kill -USR1 `cat /var/run/nginx.pid`'

deploy-nginx: scp-nginx reload-nginx

scp-mariadb:
	ssh isu01 "sudo dd of=/etc/mysql/mariadb.conf.d/50-server.cnf" < ./etc/mysql/mariadb.conf.d/50-server.cnf
	ssh isu02 "sudo dd of=/etc/mysql/mariadb.conf.d/50-server.cnf" < ./etc/mysql/mariadb.conf.d/50-server.cnf
	ssh isu03 "sudo dd of=/etc/mysql/mariadb.conf.d/50-server.cnf" < ./etc/mysql/mariadb.conf.d/50-server.cnf

restart-mariadb:
	ssh isu01 "sudo systemctl restart mariadb.service" & \
	ssh isu02 "sudo systemctl restart mariadb.service" & \
	ssh isu03 "sudo systemctl restart mariadb.service" & \
	wait

deploy-mariadb: scp-mariadb restart-mariadb

alp:
	ssh isu01 alp ltsv --file /var/log/nginx/access_log.ltsv -m '/api/condition/.*,/api/isu/[^/]*/icon,/api/isu/[^/]*/graph,/api/isu/[^/]*$,/isu/[^/]*/condition,/isu/[^/]*/graph,/isu/[^/]*$,/assets/.*' --sort sum --reverse

pt-query-digest:
	ssh isu03 sudo pt-query-digest /tmp/mysql-slow.log
