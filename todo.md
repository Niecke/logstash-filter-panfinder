# setup container
rvm install jruby

bundle install

bundle exec rspec


bundle the gem
gem build logstash-filter-<yourplugin>.gemspec

# setup codespace
sdk install java 8.0.382-amzn

rvm reinstall jruby

jruby -S bundle install

jruby -S bundle exec rspec
