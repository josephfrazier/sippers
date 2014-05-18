var assert = require('assert');
var sippers = require('../../dist/sippers.js');
var fs = require('fs');

process.chdir(__dirname);

function parseFile (path, assertion) {
  var raw = fs.readFileSync(path, 'ascii');
  assert[assertion](function () {
    try {
      var parsed = sippers.parse(raw);
    } catch (e) {
      e.message += ' at line ' + e.line + ', column ' + e.column;
      throw e;
    }
  });
}

function describeDir (path, assertion) {
  describe('parsing a ' + path + ' message', function () {
    fs.readdirSync(path).forEach(function (file) {
      it(assertion + ' for ' + file, function () {
        parseFile(path + '/' + file, assertion);
      });
    });
  });
}

describe('Torture Tests:', function () {
  describeDir('wellformed', 'doesNotThrow');
  describeDir('malformed', 'throws');
});
