from pathlib import Path


class Utils:
    @staticmethod
    def get_desktop_folder():
        home_dir = Path.home()
        desktop_folder = home_dir / 'Desktop'
        return desktop_folder

    @staticmethod
    def sanitize_filename(filename, extra_keywords=[]):
        try:
            keywords_to_exclude = ['performance', 'official', 'video', 'music', 'video', 
                                   'lyrics', 'audio', 'hd', 'hq', 'remix'] \
                                       + extra_keywords
            words = filename.split()
            sanitized_words = []
            for word in words:
                if word == '-' or word == '/' or word == '|':
                    break
                # Preserve original case for words containing apostrophes
                if "'" in word:
                    sanitized_words.append(word)
                else:
                    # Remove content after slash (/) or pipe (|) if present
                    if '/' in word:
                        word = word.split('/')[0]
                    elif '|' in word:
                        word = word.split('|')[0]
                    elif '-' in word:
                        word = word.split('-')[0]

                    sanitized_words.append(word.title() if word.lower() not in
                                           keywords_to_exclude else word)
            return ' '.join(sanitized_words)
        except Exception as e:
            print(f'Error sanitizing filename: {e}')
            raise e

    @staticmethod
    def sanitize_filename_without_stuff(filename):
        try:
            keywords_to_exclude = ['official', 'video', 'music', 'video', 
                                   'lyrics', 'audio', 'hd', 'hq', 'remix']
            words = filename.split()
            sanitized_words = []
            for word in words:
                if word == '-' or word == '/' or word == '|':
                    break
                # Preserve original case for words containing apostrophes
                if "'" in word:
                    sanitized_words.append(word)
                else:
                    # Remove content after slash (/) or pipe (|) if present
                    if '/' in word:
                        word = word.split('/')[0]
                    elif '|' in word:
                        word = word.split('|')[0]
                    elif '-' in word:
                        word = word.split('-')[0]

                    sanitized_words.append(word.title() if word.lower() not in
                                           keywords_to_exclude else word)
            return ' '.join(sanitized_words)
        except Exception as e:
            print(f'Error sanitizing filename: {e}')
            raise e