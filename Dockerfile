FROM ruby:3.4.12-alpine

ARG SHOPIFY_API_KEY
ENV SHOPIFY_API_KEY=$SHOPIFY_API_KEY \
    RAILS_ENV=production \
    BUNDLE_WITHOUT="development:test"

RUN apk add --no-cache nodejs npm git build-base sqlite-dev postgresql-dev yaml-dev gcompat bash openssl-dev tzdata
WORKDIR /app

COPY web .

RUN cd frontend && npm install
RUN bundle install

RUN cd frontend && npm run build
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rake build:all

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
