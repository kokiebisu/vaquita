# vaquita (/vəˈkiːtə/ və-KEE-tə; Phocoena sinus) 🐋

## Project Overview

vaquita is a project developed for personal use that enables downloading music from YouTube and importing it to Apple Music as an album with metadata included.

## Getting Started

### Prerequisites

- **Ruby**: Ensure you have Ruby v3.3.0 installed. If not, you can install it using [rbenv](https://github.com/rbenv/rbenv) or [rvm](https://rvm.io/).
- **Homebrew**: Some dependencies need to be installed via Homebrew. Make sure Homebrew is installed on your system. If not, install it by following the instructions on the [Homebrew website](https://brew.sh/).

Before using, configure your laptop login password:

```sh
export PASSWORD=XXXXXXXXXX
```

## Usage

You can run the daemon process which listens to any changes in playlists.txt. Paste the url and it should pick up.

```sh
make run
```

## Notes

The creator does not take any responsibility for its usage or any potential consequences. Use this software at your own risk.
