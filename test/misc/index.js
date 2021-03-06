var assert = require('assert');
var sippers = require('../../');

var roundTrip = require('../testhelpers').roundTrip;
var jsonClone = require('../testhelpers').jsonClone;

function make200 (headers) {
  return ['SIP/2.0 200 OK', 'CSeq: 1'].concat(headers).concat('\r\n').join('\r\n');
}

assert.parsedEqual = function (parsed1, parsed2) {
  assert.deepEqual(jsonClone(parsed1), jsonClone(parsed2));
};

describe('Miscellaneous Tests:', function () {
  it('parses Via containing a WSS transport', function () {
    var viaWss = make200("Via: SIP/2.0/WSS 199.7.173.182:443;branch=z9hG4bKd8ff6d97ecd0b43cd0730289e328c61f999e568c;rport");
    assert.notEqual(String, sippers.parse(viaWss).headers.Via[0].constructor);
  });

  it('parses Route containing a wss transport parameter', function () {
    var message = make200("Route: <sip:db9613574a@199.7.173.182:443;transport=wss;lr;ovid=4afad521>");
    assert.notEqual(String, sippers.parse(message).headers.Route[0].constructor);
  });

  it('parses Accept containing */*', function () {
    var message = make200("Accept: */*");
    assert.deepEqual(
      sippers.parse(message).headers.Accept[0].range,
      {
        type: '*',
        subtype: '*',
        parameters: []
      }
    );
  });

  it('parses Accept containing x-tension/*', function () {
    var message = make200("Accept: x-tension/*");
    assert.deepEqual(
      sippers.parse(message).headers.Accept[0].range,
      {
        type: 'x-tension',
        subtype: '*',
        parameters: []
      }
    );
  });

  it('parses empty Accept header', function () {
    var message = make200("Accept: ");
    assert.strictEqual(sippers.parse(message).headers.Accept.length, 0);
  });

  it('parses folding Subject header', function () {
    var message = make200("Subject:  \r\n \r\n ...finally");
    var parsed = sippers.parse(message, {startRule: 'SIP_message'});
    assert.strictEqual(parsed.headers.Subject, '...finally');
  });

  it('parses empty Subject header', function () {
    var message = make200("Subject  :     ");
    var parsed = sippers.parse(message, {startRule: 'SIP_message'});
    assert.strictEqual(parsed.headers.Subject, '');
  });

  it('parses empty folding Subject header', function () {
    var message = make200("Subject:  \r\n ");
    var parsed = sippers.parse(message, {startRule: 'SIP_message'});
    assert.strictEqual(parsed.headers.Subject, '');
  });

  it('parses empty Accept-Encoding as equivalent to "identity"', function () {
    function firstEncoding(message) {
      return sippers.parse(message, {startRule: 'SIP_message'}).headers['Accept-Encoding'][0];
    }
    var coding1 = firstEncoding(make200("Accept-Encoding:  \r\n "));
    var coding2 = firstEncoding(make200("Accept-Encoding:  \r\n identity"));
    assert.notEqual(coding1, null);
    assert.deepEqual(coding1, coding2);
  });

  it('parses malformed Contact "expires" parameters as equivalent to 3600', function () {
    function contactExpires (message) {
      return sippers.parse(message).headers.Contact[0].parameters.expires;
    }

    var expires1 = contactExpires(make200("Contact: <sip:user@host.com>;expires=malformed"));
    var expires2 = contactExpires(make200("Contact: <sip:user@host.com>;expires=3600"));
    assert.notEqual(expires1, null);
    assert.equal(expires1, 3600);
    assert.equal(expires2, 3600);
  });

  it('parses malformed Expires headers as equivalent to 3600', function () {
    function expiresHeader (message) {
      return sippers.parse(make200(message)).headers.Expires;
    }

    var expires1 = expiresHeader("Expires: malformed");
    var expires2 = expiresHeader("Expires: 3600");
    assert.notEqual(expires1, null);
    assert.equal(expires1, 3600);
    assert.equal(expires2, 3600);
  });

  it('ignores any CRLF appearing before the start-line', function () {
    var ok = make200();
    var crlfok = '\r\n\r\n' + ok;

    assert.parsedEqual(sippers.parse(crlfok), sippers.parse(ok));
  });

  // see http://tools.ietf.org/html/rfc3261#section-7.3.1
  describe('a message with non-combined multiple header fields', function () {
    var noncombinedHeaders = {
      'WWW-Authenticate': [
        'Digest realm="atlanta.com", domain="sip:boxesbybob.com", qop="auth", nonce="f84f1cec41e6cbe5aea9c8e88d359", opaque="", stale=FALSE, algorithm=MD5',
        'Digest realm="biloxi.com", domain="sip:boxesbybob.com", qop="auth", nonce="f84f1cec41e6cbe5aea9c8e88d359", opaque="", stale=FALSE, algorithm=MD5'
      ],
      'Authorization': [
        'Digest username="Alice", realm="atlanta.com", nonce="84a4cc6f3082121f32b42a2187831a9e", response="7587245234b3434cc3412213e5f113a5432"',
        'Digest username="Bob", realm="biloxi.com", nonce="84a4cc6f3082121f32b42a2187831a9e", response="7587245234b3434cc3412213e5f113a5432"'
      ],
      'Proxy-Authenticate': [
        'Digest realm="atlanta.com", domain="sip:ss1.carrier.com", qop="auth", nonce="f84f1cec41e6cbe5aea9c8e88d359", opaque="", stale=FALSE, algorithm=MD5',
        'Digest realm="biloxi.com", domain="sip:ss1.carrier.com", qop="auth", nonce="f84f1cec41e6cbe5aea9c8e88d359", opaque="", stale=FALSE, algorithm=MD5'
      ],
      'Proxy-Authorization': [
        'Digest username="Alice", realm="atlanta.com", nonce="c60f3082ee1212b402a21831ae", response="245f23415f11432b3434341c022"',
        'Digest username="Bob", realm="biloxi.com", nonce="c60f3082ee1212b402a21831ae", response="245f23415f11432b3434341c022"'
      ]
    };

    var headerList = Object.keys(noncombinedHeaders).reduce(function (list, name) {
      return list.concat(noncombinedHeaders[name].map(function (value) {
        return name + ': ' + value;
      }));
    }, []);

    var message = make200(headerList);

    var parsed;

    it('parses', function () {
      parsed = sippers.parse(message);
    });

    it('round-trips', function () {
      roundTrip(parsed);
      assert.equal(message, parsed.serialize());
    });
  });
});
