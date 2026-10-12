FROM ruby:3.4.8-slim AS build
WORKDIR /app
RUN apt-get update -qq && apt-get install --no-install-recommends -y build-essential libyaml-dev pkg-config && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock ./
ENV BUNDLE_PATH=/usr/local/bundle BUNDLE_WITHOUT=development:test
RUN bundle install && rm -rf /usr/local/bundle/cache

FROM ruby:3.4.8-slim
WORKDIR /app
RUN apt-get update -qq && apt-get install --no-install-recommends -y libyaml-0-2 libsqlite3-0 && rm -rf /var/lib/apt/lists/* && useradd -m -u 1000 rails
ENV RAILS_ENV=production BUNDLE_PATH=/usr/local/bundle BUNDLE_WITHOUT=development:test DATABASE_PATH=/app/storage/production.sqlite3
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --chown=rails:rails . .
RUN mkdir -p storage log tmp/pids && chown -R rails:rails storage log tmp
USER rails
EXPOSE 3000
CMD ["bin/container-start"]
