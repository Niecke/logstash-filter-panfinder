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

### Test in Logstash

Run a logstash container with 

```sh
docker run -it -v $HOME/git/logstash-filter-panfinder:/logstash-filter-panfinder --rm --name logstash7 logstash:7.10.2 bash
```

And add a filter under /usr/share/logstash/pipeline/logstash.conf

```
input {
  file {
    path => "/tmp/logs"
    start_position => "beginning"
  }
}

filter {
  panfinder { }
}

output {
  file {
   path => "/tmp/out"
 }
}
```

Install the Plugin

```sh
bin/logstash-plugin install /logstash-filter-panfinder/logstash-filter-panfinder-0.0.1.gem
```

Run Logstash

```sh
 bin/logstash
```

## Build

```sh
gem build logstash-filter-panfinder.gemspec
```
