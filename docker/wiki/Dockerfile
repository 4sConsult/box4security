FROM ruby
RUN apt-get -y update && apt-get -y install libicu-dev cmake && rm -rf /var/lib/apt/lists/*
RUN gem install github-linguist
RUN gem install rack execjs therubyracer
RUN gem install gollum:5.0.1
RUN gem install org-ruby  # optional
WORKDIR /wiki
CMD ["rackup"]
EXPOSE 80
