var assert = require('assert');
var sippers = require('../');

function jsonClone (obj) {
  return JSON.parse(JSON.stringify(obj));
}
module.exports.jsonClone = jsonClone;

module.exports.roundTrip = function roundTrip (parsed) {
  if (!parsed) return;
  var parsed2 = sippers.parse(parsed.serialize(), {startRule: 'SIP_message'});
  assert.deepEqual(jsonClone(parsed), jsonClone(parsed2), 'serialize/parse round-trip came back different');
};
