# README

## Install on Mac

Install this before running `bundle`:
- `brew install pkg-config`
- `brew install libexif`
- `brew install vips`
- `brew install mysql@8.4`

In case `mysql` gem failed to install anyway, try: `gem install mysql2 -v '0.5.6' -- --with-opt-dir=$(brew --prefix openssl) --with-ldflags=-L/opt/homebrew/opt/zstd/lib`

## Other

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
