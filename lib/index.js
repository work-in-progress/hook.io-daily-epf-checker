(function() {
  var DailyEpfImport, Hook, async, colors, epf, mongoose, pts, util;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Hook = require('hook.io').Hook;
  util = require('util');
  colors = require('colors');
  epf = require("itunes-epf-feedcheck");
  pts = require('persistent-task-status').client;
  mongoose = require('mongoose');
  async = require('async');
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
      self.on("daily-epf-import::ensure-tasks-finished", function(data) {
        return console.log("ensure task exists finished");
      });
      return self.emit("check-epf-status", {});
    });
  };
  util.inherits(DailyEpfImport, Hook);
  DailyEpfImport.prototype._checkEpfStatus = function(data) {
    console.log("Checking EPF status".cyan);
    return epf.check(this.epfserver.auth.username, this.epfserver.auth.password, __bind(function(err, data) {
      if (err) {
        console.error(err);
        return this.emit("epf-status-error", {
          error: err
        });
      } else {
        return this.emit("epf-status-received", {
          checkResult: data
        });
      }
    }, this));
  };
  DailyEpfImport.prototype._ensureSubTasksExists = function(taskContainer, fullOrPartial, isFull, cb) {
    var activity, file, taskList, _i, _j, _len, _len2, _ref, _ref2;
    taskList = [];
    _ref = ["download", "unzip", "untar", "import", "delete"];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      activity = _ref[_i];
      _ref2 = fullOrPartial.files;
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        file = _ref2[_j];
        taskList.push({
          taskName: "" + file.fileName + "::" + activity,
          taskData: {
            dateAsString: fullOrPartial.date.asString,
            isFull: isFull,
            fileUrl: file.fileUrl,
            fileName: file.fileName,
            month: fullOrPartial.date.month,
            day: fullOrPartial.date.day,
            year: fullOrPartial.date.year,
            activity: activity
          }
        });
      }
    }
    return async.forEachSeries(taskList, __bind(function(t, cb2) {
      return taskContainer.getTask(t.taskName, __bind(function(err, task) {
        if (err != null) {
          return cb2(err);
        }
        if (task) {
          console.log("Task " + t.taskName + " existed");
          return cb2(null);
        } else {
          return taskContainer.addTask(t.taskName, {
            taskData: t.taskData
          }, __bind(function(err, task) {
            if (err != null) {
              return cb2(err);
            }
            console.log("Task " + t.taskName + " added");
            return cb2(null);
          }, this));
        }
      }, this));
    }, this), __bind(function(err) {
      if (err != null) {
        return cb(err);
      }
      return cb(null);
    }, this));
  };
  DailyEpfImport.prototype._epfStatusReceived = function(data) {
    var inc, items, _i, _len, _ref;
    console.log("Validating EPF Status...".cyan);
    items = [];
    items.push({
      isFull: true,
      fullOrPartial: data.checkResult.full
    });
    _ref = data.checkResult.incremental;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      inc = _ref[_i];
      items.push({
        isFull: false,
        fullOrPartial: inc
      });
    }
    return async.forEachSeries(items, __bind(function(item, cb2) {
      return pts.getOrCreateTaskContainer("epf::status-import::" + item.fullOrPartial.date.asString, __bind(function(err, taskContainer2, isNew) {
        if (err != null) {
          return cb2(err);
        }
        return this._ensureSubTasksExists(taskContainer2, item.fullOrPartial, item.isFull, cb2);
      }, this));
    }, this), __bind(function(err) {
      if (err) {
        console.error(err);
        return this.emit("daily-epf-import::ensure-tasks-error", {
          error: err
        });
      } else {
        return this.emit("daily-epf-import::ensure-tasks-finished", {});
      }
    }, this));
  };
}).call(this);
