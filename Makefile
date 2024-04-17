run-daemon:
	./bin/run.sh

get-recommended:
	ruby lib/vaquita.rb --type recommendation

get-trending:
	ruby lib/vaquita.rb --type trending

get-by-music-playlist:
	ruby lib/vaquita.rb --type playlist

get-by-youtube-playlist:
	ruby lib/vaquita.rb --url

