# Use the official Ruby image
# -------------------------------------------------------------------------------------------------
  FROM ruby:3.3.5

  # Install dependencies
  # -------------------------------------------------------------------------------------------------
  RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs vim cron imagemagick \
  ghostscript ffmpeg pdftk qpdf
  
  # Set the working directory
  # -------------------------------------------------------------------------------------------------
  WORKDIR /home/hydra
  
  # Install Bundler
  # -------------------------------------------------------------------------------------------------
  RUN gem install bundler
  
  # Copy the Gemfile and Gemfile.lock into the container
  # -------------------------------------------------------------------------------------------------
  COPY ./hydra/Gemfile ./hydra/Gemfile.lock /home/hydra/
  
  # Install gems
  # -------------------------------------------------------------------------------------------------
  RUN bundle install
  
  # Copy the rest of the application code into the container
  # -------------------------------------------------------------------------------------------------
  ADD ./hydra /home/hydra
  
  # Use JEMALLOC instead
  # JEMalloc is a faster garbage collection for Ruby.
  # -------------------------------------------------------------------------------------------------
  RUN apt-get install -y libjemalloc2 libjemalloc-dev
  
  # increase ImageMagick's memory limit
  # -------------------------------------------------------------------------------------------------
  RUN sed -i -E 's/name="disk" value=".+"/name="disk" value="4GiB"/g' /etc/ImageMagick-6/policy.xml
  
  # Modifiy ImageMagick's security policy to allow reading and writing PDFs
  # -------------------------------------------------------------------------------------------------
  RUN sed -i 's/policy domain="coder" rights="none" pattern="PDF"/policy domain="coder" rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml
  
  # Install Yarn
  # -------------------------------------------------------------------------------------------------
  RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
  RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
  RUN apt-get update && apt-get install -y yarn

  # Expose port 3000 to the Docker host
  EXPOSE 3000
