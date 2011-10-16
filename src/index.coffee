Hook = require('hook.io').Hook
util = require('util')
colors = require('colors')    
epf = require "itunes-epf-feedcheck"
pts = require('persistent-task-status').client
mongoose = require('mongoose')
async = require 'async'


DailyEpfCheck = exports.DailyEpfCheck = (options) ->
  self = @
  Hook.call self, options
  self.on "hook::ready", ->  
    mongoose.connect self.mongoose.connection
  
    self.on "daily-epf-checker::epf-status-received", (data)->
      #console.log JSON.stringify(data.checkResult)
      self._epfStatusReceived(data)
    self.on "daily-epf-checker::check-epf-status", (data) ->
      self._checkEpfStatus()
      
    self.on "daily-epf-checker::ensure-tasks-finished", (data) ->
      console.log "ensure task exists finished"
    
    self.emit "daily-epf-checker::check-epf-status", {}
    setInterval (() => self.emit "daily-epf-checker::check-epf-status", {})
      , 1000 * 60 * 10
      
util.inherits DailyEpfCheck, Hook

DailyEpfCheck.prototype._checkEpfStatus = (data) ->
  console.log "Checking EPF status".cyan
  epf.check @.epfserver.auth.username, @.epfserver.auth.password, (err, data) =>
    if err
        console.error err
        @emit "daily-epf-checker::epf-status-error", error : err
    else
      @emit "daily-epf-checker::epf-status-received", checkResult : data

# Huge Pain in the A.. function. This one
# ensures that all tasks have been created for a particular
# day. fullOrPartial is the feedcheck data.
DailyEpfCheck.prototype._ensureSubTasksExists = (taskContainer,fullOrPartial,isFull,cb) ->

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
# This code is less ugly now.
DailyEpfCheck.prototype._epfStatusReceived = (data) ->
  console.log "Validating EPF Status...".cyan
  
  items = []
  items.push 
    isFull : true
    fullOrPartial: data.checkResult.full
  
  for inc in data.checkResult.incremental
    items.push 
      isFull : false
      fullOrPartial: inc
        
  async.forEachSeries items, 
    (item,cb2) => 
      pts.getOrCreateTaskContainer "epf::status-import::#{item.fullOrPartial.date.asString}", (err,taskContainer2,isNew) =>
        return cb2(err) if err? 
        @_ensureSubTasksExists taskContainer2,item.fullOrPartial,item.isFull, cb2
    ,(err) =>
      if err
        console.error err
        @emit "daily-epf-checker::ensure-tasks-error", error : err
      else
        @emit "daily-epf-checker::ensure-tasks-finished", {}

