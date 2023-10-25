FROM trmccormick/hydra_docker_build:ruby2.7

ENV RAILS_ENV production
ENV RACK_ENV production

WORKDIR /home/hydra
ADD ./hydra /home/hydra

RUN apt-get update && apt-get -y install ghostscript

# Use JEMALLOC instead
# JEMalloc is a faster garbage collection for Ruby.
# -------------------------------------------------------------------------------------------------
RUN apt-get install -y libjemalloc2
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# increase ImageMagick's memory limit
RUN sed -i -E 's/name="disk" value=".+"/name="disk" value="4GiB"/g' /etc/ImageMagick-6/policy.xml
# Modifiy ImageMagick's security policy to allow reading and writing PDFs
RUN sed -i 's/policy domain="coder" rights="none" pattern="PDF"/policy domain="coder" rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml

RUN \
  gem update --system --quiet && \
  bundle config set --local without 'development test' && \
  bundle install --jobs=4 --retry=3 
