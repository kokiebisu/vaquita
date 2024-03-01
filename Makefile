do:
	python main.py && MUSIC_FOLDER=$$(cat output_dir.txt) && echo "$$MUSIC_FOLDER" && export MUSIC_FOLDER && ./import_to_apple_music.sh "$$MUSIC_FOLDER" && rm -rf "$$MUSIC_FOLDER"
