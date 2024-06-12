start-dev-server:
	docker-compose up

start-server-clean:
	docker-compose up --build --remove-orphans

import-to-apple-music:
	./process.sh