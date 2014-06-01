var assert = require('assert');
var sippers = require('../../dist/sippers.js');

function make200 (headers) {
  return ['SIP/2.0 200 OK', 'CSeq: 1'].concat(headers).concat('\r\n').join('\r\n');
}

describe('Miscellaneous Tests:', function () {
  it('parses Via containing a WSS transport', function () {
    var viaWss = make200("Via: SIP/2.0/WSS 199.7.173.182:443;branch=z9hG4bKd8ff6d97ecd0b43cd0730289e328c61f999e568c;rport");
    assert.notEqual(String, sippers.parse(viaWss).message_headers.Via[0].constructor);
  });

  it('parses Route containing a wss transport parameter', function () {
    var message = make200("Route: <sip:db9613574a@199.7.173.182:443;transport=wss;lr;ovid=4afad521>");
    assert.notEqual(String, sippers.parse(message).message_headers.Route[0].constructor);
  });

  it('parses Accept containing */*', function () {
    var message = make200("Accept: */*");
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
    var message = make200("Accept: x-tension/*");
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
    var message = make200("Accept: ");
    assert.strictEqual(sippers.parse(message).message_headers.Accept.length, 0);
  });

  it('parses folding Subject header', function () {
    var message = make200("CSeq:1\r\nSubject:  \r\n \r\n ...finally");
    var parsed = sippers.parse(message, {startRule: 'SIP_message'});
    assert.strictEqual(parsed.message_headers.Subject, '...finally');
  });

  it('parses empty Subject header', function () {
    var message = make200("CSeq:1\r\nSubject  :     ");
    var parsed = sippers.parse(message, {startRule: 'SIP_message'});
    assert.strictEqual(parsed.message_headers.Subject, '');
  });

  it('parses empty folding Subject header', function () {
    var message = make200("CSeq:1\r\nSubject:  \r\n ");
    var parsed = sippers.parse(message, {startRule: 'SIP_message'});
    assert.strictEqual(parsed.message_headers.Subject, '');
  });

  it('parses empty Accept-Encoding as equivalent to "identity"', function () {
    function firstEncoding(message) {
      return sippers.parse(message, {startRule: 'SIP_message'}).message_headers['Accept-Encoding'][0];
    }
    var coding1 = firstEncoding(make200("Accept-Encoding:  \r\n "));
    var coding2 = firstEncoding(make200("Accept-Encoding:  \r\n identity"));
    assert.notEqual(coding1, null);
    assert.deepEqual(coding1, coding2);
  });

  it('parses malformed Contact "expires" parameters as equivalent to 3600', function () {
    function contactExpires (message) {
      return sippers.parse(message).message_headers.Contact[0].params.expires;
    }

    var expires1 = contactExpires(make200("Contact: <sip:user@host.com>;expires=malformed"));
    var expires2 = contactExpires(make200("Contact: <sip:user@host.com>;expires=3600"));
    assert.notEqual(expires1, null);
    assert.equal(expires1, 3600);
    assert.equal(expires2, 3600);
  });

  it('parses malformed Expires headers as equivalent to 3600', function () {
    function expiresHeader (message) {
      return sippers.parse(make200(message)).message_headers.Expires;
    }

    var expires1 = expiresHeader("Expires: malformed");
    var expires2 = expiresHeader("Expires: 3600");
    assert.notEqual(expires1, null);
    assert.equal(expires1, 3600);
    assert.equal(expires2, 3600);
  });
});
