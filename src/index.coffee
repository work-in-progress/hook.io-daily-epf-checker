Hook = require('hook.io').Hook
util = require('util')
colors = require('colors')    
epf = require "itunes-epf-feedcheck"
pts = require('persistent-task-status').client
mongoose = require('mongoose')
async = require 'async'
  
DailyEpfImport = exports.DailyEpfImport = (options) ->
  self = @
  Hook.call self, options
  
  self.on "hook::ready", ->  
    mongoose.connect self.mongoose.connection
  
    self.on "epf-status-received", (data)->
      #console.log JSON.stringify(data.checkResult)
      self._epfStatusReceived(data)
    self.on "check-epf-status", (data) ->
      self._checkEpfStatus()
    
    self.emit "check-epf-status", {}
        
    #for key of self.feeds
    #  ((feed) ->
    #    reader = new FeedSub(feed.url, feed)
    #    reader.on "item", (item) ->
    #      self.emit feed.name + "::item", item
    #
    #    reader.start()
    #  ) self.feeds[key]

util.inherits DailyEpfImport, Hook

DailyEpfImport.prototype._checkEpfStatus = (data) ->
  console.log "Checking EPF status".cyan
  epf.check @.epfserver.auth.username, @.epfserver.auth.password, (err, data) =>
    if err
        console.error err
    else
      @emit "epf-status-received", checkResult : data

# Huge Pain in the A.. function. This one
# ensures that all tasks have been created for a particular
# day. fullOrPartial is the feedcheck data.
DailyEpfImport.prototype._ensureSubTasksExists = (taskContainer,fullOrPartial,isFull,cb) ->

  taskList = []
  
  for activity in ["download","unzip","untar","import","delete"]
    for file in fullOrPartial.files
      taskList.push 
        taskName : "#{file.fileName}::#{activity}"
        taskData : 
          dateAsString : fullOrPartial.date.asString
          isFull : isFull
          fileUrl : file.fileUrl
          fileName : file.fileName
          month : fullOrPartial.date.month
          day : fullOrPartial.date.day
          year : fullOrPartial.date.year
          activity : activity

  async.forEachSeries taskList, 
    (t,cb2) => 
      taskContainer.getTask t.taskName, (err,task) =>
        return cb2(err) if err?

        if task
          console.log "Task #{t.taskName} existed"
          cb2(null)
        else
          taskContainer.addTask t.taskName,taskData : t.taskData, (err,task) =>
            return cb2(err) if err?
            console.log "Task #{t.taskName} added"
            cb2(null)
    ,(err) =>
      return cb(err) if err?
      cb(null)
      
# We have received a status back, now we need
# to check if this is a new one. To do that
# we first check for the full feed, if it does
# not exists we start with that, then move on to the
# intermediates.
DailyEpfImport.prototype._epfStatusReceived = (data) ->

  console.log "EPF Status received, validating...".cyan
  
  pts.getOrCreateTaskContainer "epf::status-import::#{data.checkResult.full.date.asString}", (err,taskContainer,isNew) =>
    if err
      console.error err
    else
      @_ensureSubTasksExists taskContainer,data.checkResult.full,true, (err) =>
        if err
          console.error err
        else
          async.forEachSeries data.checkResult.incremental,
            (inc,cb2) =>
              pts.getOrCreateTaskContainer "epf::status-import::#{inc.date.asString}", (err,taskContainer2,isNew) =>
                return cb2(err) if err? 
                @_ensureSubTasksExists taskContainer2,inc,false, cb2
              
            ,(err) =>
              if err
                console.error err
              else
              console.log "ensure task exists finished"
          
      # make the above async, then handle all the other partials
        