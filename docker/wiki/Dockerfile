FROM ruby
RUN apt-get -y update && apt-get -y install libicu-dev cmake && rm -rf /var/lib/apt/lists/*
RUN gem install github-linguist
RUN gem install gollum:5.0.1
RUN gem install org-ruby  # optional
WORKDIR /wiki
RUN git clone https://cMeyer:QVXq8i5FxSNEH_YEmze3@gitlab.am-gmbh.de/cmeyer/b4s-docs.git .
ENTRYPOINT ["gollum", "--port", "80", "--page-file-dir", "BOX4security", "--base-path /docs"
EXPOSE 80
