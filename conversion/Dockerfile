FROM debian:latest

RUN apt-get update

RUN apt-get install --no-install-recommends -y \
    imagemagick \
    ghostscript \
    ffmpeg \
    cron

ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Set up the cron job to run the script
ADD crontab.txt /crontab.txt
RUN /usr/bin/crontab /crontab.txt

WORKDIR /convert

ADD ./startup.sh /usr/bin/
RUN chmod -v +x /usr/bin/startup.sh
ENTRYPOINT ["/usr/bin/startup.sh"]