from pathlib import Path


def get_desktop_folder():
    home_dir = Path.home()
    desktop_folder = home_dir / 'Desktop'
    return desktop_folder


def sanitize_filename(filename, extra_keywords=[]):
    try:
        excluded_keywords = _exclude_keywords(filename, extra_keywords)
        if '-' in excluded_keywords:
            sanitized_words = [w.title().strip() for w in excluded_keywords.split('-')]
        elif '/' in excluded_keywords:
            sanitized_words = [w.title().strip() for w in excluded_keywords.split('/')]
        else:
            sanitized_words = [w.title().strip() for w in excluded_keywords.split()]
        return ' '.join(sanitized_words).strip()
    except Exception as e:
        print(f'Error sanitizing filename: {e}')
        raise e


def _exclude_keywords(filename, extra_keywords):
    KEYWORDS_TO_EXCLUDE = ['performance', 'official', 'video', 'music',
                           'video', 'lyrics', 'audio', 'hd', 'hq',
                           'remix', '[music', 'video]'] + extra_keywords
    result = []
    for word in filename.split():
        if word.lower() not in KEYWORDS_TO_EXCLUDE:
            result.append(word.title())
    return ' '.join(result)
