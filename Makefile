start-server:
	docker-compose up

start-server-clean:
	docker-compose up --build --remove-orphans

combine-playlist-videos:
	docker-compose exec server ./combine_playlist_videos.sh