start-server:
	docker-compose up

start-server-clean:
	docker-compose up --build --remove-orphans

run-daemon:
	./bin/daemon.sh

get-recommended:
	ruby lib/vaquita.rb --type recommendation

get-trending:
	ruby lib/vaquita.rb --type trending

get-by-music-playlist:
	ruby lib/vaquita.rb --type playlist

get-by-youtube-playlist:
	ruby lib/vaquita.rb --url

