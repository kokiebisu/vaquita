start-server:
	docker-compose up

start-server-clean:
	docker-compose up --build --remove-orphans
