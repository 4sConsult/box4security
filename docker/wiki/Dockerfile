FROM ruby:2.7.1
ADD config.ru /wiki/config.ru
RUN apt-get -y update && \
  apt-get -y install libicu-dev cmake && \
  rm -rf /var/lib/apt/lists/* && \
  gem install github-linguist && \
  gem install rack execjs therubyracer && \
  gem install gollum:5.0.1 && \
  gem install org-ruby

WORKDIR /wiki
CMD ["rackup"]
EXPOSE 80
