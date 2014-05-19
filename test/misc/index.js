var assert = require('assert');
var sippers = require('../../dist/sippers.js');

describe('Miscellaneous Tests:', function () {
  it('parses Via containing a WSS transport', function () {
    var viaWss = "SIP/2.0 200 OK\r\nVia: SIP/2.0/WSS 199.7.173.182:443;branch=z9hG4bKd8ff6d97ecd0b43cd0730289e328c61f999e568c;rport\r\n\r\n";
    assert.notEqual(String, sippers.parse(viaWss).message_headers.Via[0].constructor);
  });

  it('parses Route containing a wss transport parameter', function () {
    var message = "ACK sip:mod_sofia@199.7.173.152:5060 SIP/2.0\r\nRoute: <sip:db9613574a@199.7.173.182:443;transport=wss;lr;ovid=4afad521>\r\n\r\n";
    assert.notEqual(String, sippers.parse(message).message_headers.Route[0].constructor);
  });
});
