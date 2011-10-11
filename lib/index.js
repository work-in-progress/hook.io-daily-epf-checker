(function() {
  var DailyEpfImport, Hook, colors, util;
  Hook = require('hook.io').Hook;
  util = require('util');
  colors = require('colors');
  DailyEpfImport = exports.DailyEpfImport = function(options) {
    var self;
    self = this;
    Hook.call(self, options);
    return self.on("hook::ready", function() {
      return console.log("DailyEpfImport started");
    });
  };
  util.inherits(DailyEpfImport, Hook);
}).call(this);
