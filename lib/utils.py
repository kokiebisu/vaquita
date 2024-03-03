from pathlib import Path


def get_desktop_folder():
    home_dir = Path.home()
    desktop_folder = home_dir / 'Desktop'
    return desktop_folder


def sanitize_filename(filename, extra_keywords=[]):
    try:
        keywords_to_exclude = ['performance', 'official', 'video', 'music', 
                               'video', 'lyrics', 'audio', 'hd', 'hq', 
                               'remix', '[music', 'video]'] \
                                    + extra_keywords
        words = []
        temp = filename.split()
        for word in temp:
            if word.lower() not in keywords_to_exclude:
                words.append(word.title())
        words = ' '.join(words)
        if '-' in words:
            sanitized_words = [w.title().strip() for w in words.split('-')]
        elif '/' in words:
            sanitized_words = [w.title().strip() for w in words.split('/')]
        else:
            sanitized_words = [w.title().strip() for w in words.split()]
        return ' '.join(sanitized_words).strip()
    except Exception as e:
        print(f'Error sanitizing filename: {e}')
        raise e
