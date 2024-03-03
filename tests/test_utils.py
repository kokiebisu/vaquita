import unittest
from pathlib import Path

from lib.utils import get_desktop_folder, sanitize_filename


class TestUtils(unittest.TestCase):

    def test_get_desktop_folder(self):
        desktop_folder = get_desktop_folder()
        self.assertIsInstance(desktop_folder, Path)
        self.assertTrue(desktop_folder.is_dir())
        self.assertTrue(desktop_folder.exists())

    def test_sanitize_filename(self):
        # # Test Case 1
        filename = "Artist - Song Title (Remix)"
        sanitized_filename = sanitize_filename(filename, ['artist'])
        expected_result = "Song Title (Remix)"
        self.assertEqual(sanitized_filename, expected_result)

        # # Test Case 2
        filename = "Song Title (Remix) - Artist"
        sanitized_filename = sanitize_filename(filename, ['artist'])
        expected_result = "Song Title (Remix)"
        self.assertEqual(sanitized_filename, expected_result)

        # Test Case 3
        filename = "Art-Ist / Song [Music Video]"
        sanitized_filename = sanitize_filename(filename, ['art-ist'])
        expected_result = "Song"
        self.assertEqual(sanitized_filename, expected_result)

        # Test Case 4
        filename = "アーティスト - 曲名 - Song"
        sanitized_filename = sanitize_filename(filename, ['artist', 'アーティスト'])
        expected_result = "曲名 Song"
        self.assertEqual(sanitized_filename, expected_result)

        # Test Case 5
        filename = "アーティスト Artist - LADY"
        sanitized_filename = sanitize_filename(filename, ['artist', 'アーティスト'])
        expected_result = "Lady"
        self.assertEqual(sanitized_filename, expected_result)


if __name__ == '__main__':
    unittest.main()
