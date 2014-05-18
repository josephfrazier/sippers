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
      if (assertion !== 'throws') {
        console.error(path);
        console.info(raw);
        console.warn(e);
      }
      throw e;
    }
  });
}

function describeDir (path, assertion) {
  describe(path, function () {
    fs.readdirSync(path).forEach(function (file) {
      it(assertion + ' on torture test: ' + file, function () {
        parseFile(path + '/' + file, assertion);
      });
    });
  });
}

describe('Torture Tests', function () {
  describeDir('wellformed', 'doesNotThrow');
  describeDir('malformed', 'throws');
});
