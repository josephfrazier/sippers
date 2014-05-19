var assert = require('assert');
var sippers = require('../../dist/sippers.js');

describe('Miscellaneous Tests:', function () {
  it('parses Via containing a WSS transport', function () {
    var viaWss = "SIP/2.0 200 OK\r\nVia: SIP/2.0/WSS 199.7.173.182:443;branch=z9hG4bKd8ff6d97ecd0b43cd0730289e328c61f999e568c;rport\r\n\r\n";
    assert.notEqual(String, sippers.parse(viaWss).message_headers.Via[0].constructor);
  });
});
