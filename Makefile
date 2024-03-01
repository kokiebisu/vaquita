do:
	@if [ -z "$$PASSWORD" ]; then \
		echo "\033[0;31mError: PASSWORD is not set.\033[0m"; \
	else \
		echo "\033[0;32mRunning python main.py...\033[0m" \
		&& python main.py \
		&& MUSIC_FOLDER=$$(cat output_dir.txt) \
		&& export MUSIC_FOLDER \
		&& echo "\033[0;36mRunning import_to_apple_music.sh...\033[0m" \
		&& ./import_to_apple_music.sh "$$MUSIC_FOLDER" \
		&& rm -rf "$$MUSIC_FOLDER" \
		&& rm -rf "output_dir.txt" \
		&& echo "\033[0;32mProcess completed successfully!\033[0m"; \
	fi \
	&& stty sane;