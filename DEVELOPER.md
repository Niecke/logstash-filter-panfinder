# logstash-filter-panfinder
Panfinder filter plugin.

## Docker Dev Environment

This plugin is developed within a docker container but you could also install jruby directly on your machine or within another VM.
To run a docker container use the following command (maybe change the path to this repo):

```sh
docker run -it --name panfinder --rm -v $HOME/git/logstash-filter-panfinder:/logstash-filter-panfinder ruby:latest bash
```

Within the container execute the follwing command to set everything up:

```sh
cd /logstash-filter-panfinder && bundle install
```

## Testing

To execute all tests execute the following command:

```sh
bundle exec rspec
```
