# Use Ruby version 3.3.0 as the parent image
FROM ruby:3.3.0

# Set the working directory in the container
WORKDIR /usr/src/app

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libxml2-dev \
    libxslt-dev \
    imagemagick \
    libtag1-dev \
    ffmpeg \    
    build-essential \
    libpq-dev \
    nodejs \
    yarn \
    wget \
    jq \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install yt-dlp
RUN wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp && \
    chmod a+rx /usr/local/bin/yt-dlp

# Copy the current directory contents into the container at /usr/src/app
COPY . .

# Install any needed packages specified in Gemfile
RUN bundle install

# Make port 4567 available to the world outside this container
EXPOSE 4567

#Health Check
HEALTHCHECK CMD curl --fail http://youtube.com/ || exit 1

# Run app.rb when the container launches
CMD ["ruby", "app.rb"]
