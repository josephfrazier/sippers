var assert = require('assert');
var sippers = require('../../dist/sippers.js');
var fs = require('fs');

process.chdir(__dirname);

function assertivelyParse (name) {
  var path = 'dat/' + name + '.dat';
  var raw = fs.readFileSync(path, 'ascii');
  var parsed;

  assert.doesNotThrow(function () {
    try {
      parsed = sippers.parse(raw);
    } catch (e) {
      e.message += ' at line ' + e.line + ', column ' + e.column + ' of ' + path;
      throw e;
    }
  });

  return parsed;
}

describe('RFC 4475 Torture Tests', function () {
  describe('3.1. Parser Tests (syntax)', function () {
    describe('3.1.1. Valid Messages', function () {
      describe('3.1.1.1. A Short Tortuous INVITE', function () {
        var name = 'wsinv';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });
      });

      describe('3.1.1.2. Wide Range of Valid Characters', function () {
        var name = 'intmeth';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });
      });

      describe('3.1.1.3. Valid Use of the % Escaping Mechanism', function () {
        var name = 'esc01';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('The Request-URI has sips:user@example.com embedded in its userpart.', function () {
          assert.strictEqual('sips:user@example.com', parsed.Request_Line.Request_URI.userinfo.user);
        });

        it('The From and To URIs have escaped characters in their userparts.', function () {
          assert.strictEqual('I have spaces', parsed.message_headers.From.addr.userinfo.user);
          assert.strictEqual('user', parsed.message_headers.To.addr.userinfo.user);
        });

        it('The Contact URI has escaped characters in the URI parameters.', function () {
          assert.deepEqual(
            parsed.message_headers.Contact[0].addr.uri_parameters,
            {
              "lr": null,
              "name": "value%41"
            }
          );
        });
      });

      describe('3.1.1.4. Escaped Nulls in URIs', function () {
        var name = 'escnull';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('has From/To users of "null-%00-null"', function () {
          assert.strictEqual('null-\u0000-null', parsed.message_headers.From.addr.userinfo.user);
          assert.strictEqual('null-\u0000-null', parsed.message_headers.To.addr.userinfo.user);
        });

        it('has first Contact user of "%00"', function () {
          assert.strictEqual('\u0000', parsed.message_headers.Contact[0].addr.userinfo.user);
        });

        it('has second Contact user of "%00%00"', function () {
          assert.strictEqual('\u0000\u0000', parsed.message_headers.Contact[1].addr.userinfo.user);
        });
      });

      describe('3.1.1.5. Use of % When It Is Not an Escape', function () {
        var name = 'esc02';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('The request method is unknown.  It is NOT equivalent to REGISTER.', function () {
          assert.strictEqual('RE%47IST%45R', parsed.Request_Line.Method);
        });

        it('The display name portion of the To and From header fields is "%Z%45".', function () {
          assert.strictEqual('%Z%45', parsed.message_headers.To.addr.display_name);
          assert.strictEqual('%Z%45', parsed.message_headers.From.addr.display_name);
        });

        it('This message has two Contact header field values, not three.', function () {
          assert.strictEqual(2, parsed.message_headers.Contact.length);
        });
      });

      describe('3.1.1.6. Message with No LWS between Display Name and <', function () {
        var name = 'lwsdisp';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });
      });

      describe('3.1.1.7. Long Values in Header Fields', function () {
        var name = 'longreq';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });
      });

      describe('3.1.1.8. Extra Trailing Octets in a UDP Datagram', function () {
        var name = 'dblreq';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('is a REGISTER request (not an INVITE)', function () {
          assert.strictEqual('REGISTER', parsed.Request_Line.Method);
        });
      });

      describe('3.1.1.9. Semicolon-Separated Parameters in URI User Part', function () {
        var name = 'semiuri';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('The Request-URI will parse so that the user part is "user;par=u@example.net".', function () {
          assert.strictEqual('user;par=u@example.net', parsed.Request_Line.Request_URI.userinfo.user);
        });
      });

      describe('3.1.1.10. Varied and Unknown Transport Types', function () {
        var name = 'semiuri';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });
      });

      describe('3.1.1.11. Multipart MIME Message', function () {
        var name = 'mpart01';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });
      });

      describe('3.1.1.12. Unusual Reason Phrase', function () {
        var name = 'unreason';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });
      });

      describe('3.1.1.13. Empty Reason Phrase', function () {
        var name = 'noreason';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('contains no reason phrase', function () {
          assert.strictEqual('', parsed.Status_Line.Reason_Phrase);
        });
      });
    });
  });
});
