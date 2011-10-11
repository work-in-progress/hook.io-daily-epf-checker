Hook = require('hook.io').Hook
util = require('util')
colors = require('colors')    
  
DailyEpfImport = exports.DailyEpfImport = (options) ->
  self = @
  Hook.call self, options
  self.on "hook::ready", ->
    console.log "DailyEpfImport started"
    #for key of self.feeds
    #  ((feed) ->
    #    reader = new FeedSub(feed.url, feed)
    #    reader.on_ "item", (item) ->
    #      self.emit feed.name + "::item", item
    #
    #    reader.start()
    #  ) self.feeds[key]

util.inherits DailyEpfImport, Hook
  