(function() {
  var DailyEpfImport, Hook, colors, epf, mongoose, pts, util;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Hook = require('hook.io').Hook;
  util = require('util');
  colors = require('colors');
  epf = require("itunes-epf-feedcheck");
  pts = require('persistent-task-status').client;
  mongoose = require('mongoose');
  DailyEpfImport = exports.DailyEpfImport = function(options) {
    var self;
    self = this;
    Hook.call(self, options);
    return self.on("hook::ready", function() {
      mongoose.connect(self.mongoose.connection);
      self.on("epf-status-received", function(data) {
        return self._epfStatusReceived(data);
      });
      self.on("check-epf-status", function(data) {
        return self._checkEpfStatus();
      });
      return self.emit("check-epf-status", {});
    });
  };
  util.inherits(DailyEpfImport, Hook);
  DailyEpfImport.prototype._checkEpfStatus = function(data) {
    console.log("Checking EPF status".cyan);
    return epf.check(this.epfserver.auth.username, this.epfserver.auth.password, __bind(function(err, data) {
      if (err) {
        return console.error(err);
      } else {
        return this.emit("epf-status-received", {
          checkResult: data
        });
      }
    }, this));
  };
  DailyEpfImport.prototype._ensureSubTasksExists = function(taskContainer, fullOrPartial, cb) {
    var taskName, tn;
    tn = fullOrPartial.files[0];
    taskName = "" + tn.fileName + "::download";
    return taskContainer.getTask(taskName, __bind(function(err, task) {
      if (err != null) {
        return cb(err);
      }
      if (task) {
        console.log("Task existed");
        return cb(null);
      } else {
        return taskContainer.addTask(taskName, {
          taskData: {
            fileUrl: tn.fileUrl
          }
        }, __bind(function(err, task) {
          if (err != null) {
            return cb(err);
          }
          console.log("Task added");
          return cb(null);
        }, this));
      }
    }, this));
  };
  DailyEpfImport.prototype._epfStatusReceived = function(data) {
    console.log("EPF Status received, validating...".cyan);
    return pts.getOrCreateTaskContainer("epf::status-import::" + data.checkResult.full.date.asString, __bind(function(err, taskContainer, isNew) {
      if (err) {
        return console.error(err);
      } else {
        return this._ensureSubTasksExists(taskContainer, data.checkResult.full, __bind(function(err) {
          if (err) {
            return console.error(err);
          } else {
            return console.log("ensure task exists finished");
          }
        }, this));
      }
    }, this));
  };
}).call(this);
