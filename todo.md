# setup container
rvm install jruby

bundle install

bundle exec rspec


bundle the gem
gem build logstash-filter-<yourplugin>.gemspec