## About hook.io-daily-epf-import

This composite hook queries the Apple iTunes EPF server for new data. If new data is available the data will be downloaded, then uncompressed, then untarred, then
imported into a mongodb.


[![Build Status](https://secure.travis-ci.org/freshfugu/hook.io-daily-epf-import.png)](http://travis-ci.org/freshfugu/hook.io-daily-epf-import)

Please note that travis-ci.org, at this point in time, does not test this correctly because the nock mocking library needs node 0.4.10 but travis runs on 0.4.8

## Install

	npm -g install hook.io-daily-epf-import

## Usage

	./bin/daily-epf-import 


### Coffeescript

    
### Javascript


## Advertising :)

Check out http://freshfugu.com and http://scottyapp.com

Follow us on Twitter at @getscottyapp and @freshfugu and like us on Facebook please. Every mention is welcome and we follow back.

## Trivia

Listened to lots of Nicki Minaj while writing this.

## Release Notes

### 0.0.1
* First version

## Internal Stuff

* npm run-script watch
* npm link
* npm adduser
* npm publish

## Contributing to hook.io-daily-epf-import
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the package.json, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Martin Wawrusch. See LICENSE for
further details.


