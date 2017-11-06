redis-trib.rb:
	wget http://download.redis.io/redis-stable/src/redis-trib.rb

.PHONY: confs
confs:
	rm conf/*.conf || true
	cd conf && bash make.sh

docker-create:
	for port in {7001..7006}; do \
	  echo "Creating Redis @ $$port"; \
	  docker run -d --name redis-$$port --net=host -v $(PWD)/conf/$$port.conf:/redis.conf redis redis-server /redis.conf; \
	done

	docker ps | grep redis
	sudo netstat -ntlp | grep :700

docker-remove:
	for port in {7001..7006}; do \
	  echo "Removing Redis @ $$port"; \
	  docker rm -f redis-$$port || true; \
	done

docker-recreate: confs docker-remove docker-create

cluster-create:
	ruby redis-trib.rb create --replicas 1 \
	  127.0.0.1:7001 \
	  127.0.0.1:7002 \
	  127.0.0.1:7003 \
	  127.0.0.1:7004 \
	  127.0.0.1:7005 \
	  127.0.0.1:7006

run:
	for i in {7001..7006}; do echo -ne "$$i => "; redis-cli -p $$i '$(command)'; done

logs:
	docker logs --tail=10 -f redis-7001

dbsize:
	make run command=dbsize

check:
	ruby redis-trib.rb check :7001

info:
	ruby redis-trib.rb info :7001

check-role:
	for port in {7001..7006}; do \
	  echo -ne "$$port => "; \
	  redis-cli -p $$port info | grep role; \
	done

get-master-ids:
	@for port in {7001..7003}; do \
	  echo -ne "$$port => "; \
	  redis-cli -p 7001 cluster nodes | grep $$port | awk '{print $1}'; \
	done

all: redis-trib.rb confs docker-create cluster-create
