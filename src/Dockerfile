FROM ruby:3.2-buster
WORKDIR /usr/src/app
COPY Gemfile ./
RUN gem install bundler && bundle config set --local without 'test'
COPY . ./
RUN bundle install
CMD ["ruby", "./app.rb"]