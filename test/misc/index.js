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

  it('parses Accept containing */*', function () {
    var message = "SIP/2.0 200 OK\r\nAccept: */*\r\n\r\n";
    assert.deepEqual(
      sippers.parse(message).message_headers.Accept[0].media_range,
      {
        m_type: '*',
        m_subtype: '*',
        m_parameters: []
      }
    );
  });

  it('parses Accept containing x-tension/*', function () {
    var message = "SIP/2.0 200 OK\r\nAccept: x-tension/*\r\n\r\n";
    assert.deepEqual(
      sippers.parse(message).message_headers.Accept[0].media_range,
      {
        m_type: 'x-tension',
        m_subtype: '*',
        m_parameters: []
      }
    );
  });

  it('parses empty Accept header', function () {
    var message = "SIP/2.0 200 OK\r\nAccept: \r\n\r\n";
    assert.strictEqual(sippers.parse(message).message_headers.Accept.length, 0);
  });

  it('parses folding Subject header', function () {
    var message = "SIP/2.0 200 OK\r\nSubject:  \r\n \r\n ...finally\r\n\r\n";
    var parsed = sippers.parse(message, {startRule: 'SIP_message'});
    assert.strictEqual(parsed.message_headers.Subject, '...finally');
  });

  it('parses empty Subject header', function () {
    var message = "SIP/2.0 200 OK\r\nSubject  :     \r\n\r\n";
    var parsed = sippers.parse(message, {startRule: 'SIP_message'});
    assert.strictEqual(parsed.message_headers.Subject, '');
  });

  it('parses empty folding Subject header', function () {
    var message = "SIP/2.0 200 OK\r\nSubject:  \r\n \r\n\r\n";
    var parsed = sippers.parse(message, {startRule: 'SIP_message'});
    assert.strictEqual(parsed.message_headers.Subject, '');
  });

  it('parses empty Accept-Encoding as equivalent to "identity"', function () {
    function firstEncoding(message) {
      return sippers.parse(message, {startRule: 'SIP_message'}).message_headers['Accept-Encoding'][0];
    }
    var coding1 = firstEncoding("SIP/2.0 200 OK\r\nAccept-Encoding:  \r\n \r\n\r\n");
    var coding2 = firstEncoding("SIP/2.0 200 OK\r\nAccept-Encoding:  \r\n identity\r\n\r\n");
    assert.notEqual(coding1, null);
    assert.deepEqual(coding1, coding2);
  });
});
