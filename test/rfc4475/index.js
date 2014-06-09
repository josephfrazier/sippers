var assert = require('assert-diff');
var sippers = require('../../dist/sippers.js');
var fs = require('fs');

process.chdir(__dirname);

function assertivelyParse (name, error) {
  var path = 'dat/' + name + '.dat';
  var raw = fs.readFileSync(path, 'ascii');
  var parsed;

  var assertion = error !== undefined ? 'throws' : 'doesNotThrow';
  assert[assertion](function () {
    parsed = sippers.parse(raw);
  }, error);

  return parsed;
}

function roundTrip (parsed) {
  if (!parsed) return;
  var parsed2 = sippers.parse(parsed.serialize(), {startRule: 'SIP_message'});
  assert.deepEqual(jsonClone(parsed), jsonClone(parsed2), 'serialize/parse round-trip came back different');
}

function jsonClone (obj) {
  return JSON.parse(JSON.stringify(obj));
}

function repeat (str) {
  return str.replace(/<repeat count=(\d*)>([^<]*)<\/repeat>/g, function (match, count, value) {
    var repeated = '';
    count = parseInt(count, 10);
    for ( ; count > 0; count--) {
      repeated += value;
    }
    return repeated;
  });
}

// adapted from http://stackoverflow.com/a/4209150
function hex (str) {
  return str.replace(/<hex>([^<]*)<\/hex>/g, function (match, encoded) {
    return encoded.replace(/([0-9A-F]{2})/g, function (match, pair) {
      return String.fromCharCode(parseInt(pair, 16));
    });
  });
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

        it('round-trips', function () {roundTrip(parsed);});

        it('has escaped characters within quotes', function () {
          if (parsed) assert.equal(
            "J Rosenberg \\\"",
            parsed.headers.From.addr.name
          );
          if (parsed) assert.equal(
            "Quoted string \"\"",
            parsed.headers.Contact[0].addr.name
          );
        });

        it('has an empty Subject', function () {
          if (parsed) assert.equal('', parsed.headers.Subject);
        });

        it('has a mix of short and long form for the same header field name', function () {
          if (parsed) assert.equal(3, parsed.headers.Via.length);
        });

        it('has an unknown Request-URI parameter', function () {
          if (parsed) assert.strictEqual(null, parsed.Request.URI.parameters.unknownparam);
        });

        it('has unknown header fields', function () {
          if (parsed) assert.equal(
            'newfangled value continued newfangled value',
            parsed.headers.NewFangledHeader
          );
        });

        it('has an unknown header field with a value that would be syntactically invalid if it were defined in terms of generic-param', function () {
          if (parsed) assert.equal(';;,,;;,;', parsed.headers.UnknownHeaderWithUnusualValue);
        });

        it('has unknown parameters of a known header field', function () {
          if (parsed) assert.strictEqual('newvalue', parsed.headers.Contact[0].parameters.newparam);
        });

        it('has a uri parameter with no value', function () {
          if (parsed) assert.strictEqual(null, parsed.headers.Route[0].addr.parameters['unknown-no-value']);
        });

        it('has a header parameter with no value', function () {
          if (parsed) assert.strictEqual(null, parsed.headers.Contact[0].parameters.secondparam);
        });

        it('has integer fields (Max-Forwards and CSeq) with leading zeros', function () {
          if (parsed) assert.equal(68, parsed.headers['Max-Forwards']);
          if (parsed) assert.equal(9, parsed.headers.CSeq.number);
        });
      });

      describe('3.1.1.2. Wide Range of Valid Characters', function () {
        var name = 'intmeth';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});
      });

      describe('3.1.1.3. Valid Use of the % Escaping Mechanism', function () {
        var name = 'esc01';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('The Request-URI has sips:user@example.com embedded in its userpart.', function () {
          assert.equal('sips:user@example.com', parsed.Request.URI.user);
        });

        it('The From and To URIs have escaped characters in their userparts.', function () {
          assert.equal('I have spaces', parsed.headers.From.addr.user);
          assert.equal('user', parsed.headers.To.addr.user);
        });

        it('The Contact URI has escaped characters in the URI parameters.', function () {
          assert.deepEqual(
            jsonClone(parsed.headers.Contact[0].addr.parameters),
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

        it('round-trips', function () {roundTrip(parsed);});

        it('has From/To users of "null-%00-null"', function () {
          assert.equal('null-\u0000-null', parsed.headers.From.addr.user);
          assert.equal('null-\u0000-null', parsed.headers.To.addr.user);
        });

        it('has first Contact user of "%00"', function () {
          assert.equal('\u0000', parsed.headers.Contact[0].addr.user);
        });

        it('has second Contact user of "%00%00"', function () {
          assert.equal('\u0000\u0000', parsed.headers.Contact[1].addr.user);
        });
      });

      describe('3.1.1.5. Use of % When It Is Not an Escape', function () {
        var name = 'esc02';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('The request method is unknown.  It is NOT equivalent to REGISTER.', function () {
          assert.strictEqual('RE%47IST%45R', parsed.Request.Method);
        });

        it('The display name portion of the To and From header fields is "%Z%45".', function () {
          assert.equal('%Z%45', parsed.headers.To.addr.name);
          assert.equal('%Z%45', parsed.headers.From.addr.name);
        });

        it('This message has two Contact header field values, not three.', function () {
          assert.strictEqual(2, parsed.headers.Contact.length);
        });
      });

      describe('3.1.1.6. Message with No LWS between Display Name and <', function () {
        var name = 'lwsdisp';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('has a From display-name of "caller"', function () {
          if (parsed) assert.equal('caller', parsed.headers.From.addr.name);
        });
      });

      describe('3.1.1.7. Long Values in Header Fields', function () {
        var name = 'longreq';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        describe('The To header field', function () {
          it('has a long display name', function () {
            if (!parsed) return;

            assert.equal(
              repeat('I have a user name of <repeat count=10>extreme</repeat> proportion'),
              parsed.headers.To.addr.name
            );
          });

          it('has long uri parameter names and values', function () {
            if (!parsed) return;

            assert.equal(
              repeat('very<repeat count=20>long</repeat>value'),
              parsed.headers.To.addr.parameters.unknownparam1
            );

            assert.equal(
              'shortvalue',
              parsed.headers.To.addr.parameters[repeat('longparam<repeat count=25>name</repeat>')]
            );

            assert.strictEqual(
              null,
              parsed.headers.To.addr.parameters[repeat('very<repeat count=25>long</repeat>ParameterNameWithNoValue')]
            );
          });
        });

        describe('The From header field', function () {
          it('has an amazingly long caller name', function () {
            if (parsed) assert.equal(
              repeat('<repeat count=5>amazinglylongcallername</repeat>'),
              parsed.headers.From.addr.user
            );
          });

          it('has long header parameter names and values', function () {
            if (!parsed) return;

            assert.equal(
              repeat('unknowheaderparam<repeat count=15>value</repeat>'),
              parsed.headers.From.parameters[repeat('unknownheaderparam<repeat count=20>name</repeat>')]
            );

            assert.strictEqual(
              null,
              parsed.headers.From.parameters[repeat('unknownValueless<repeat count=10>paramname</repeat>')]
            );
          });

          it('has, in particular, a very long tag', function () {
            if (parsed) assert.equal(
              repeat('12<repeat count=50>982</repeat>424'),
              parsed.headers.From.parameters.tag
            );
          });
        });

        describe('The Call-ID header field', function () {
          it('is one long token', function () {
            assert.equal(
              parsed.headers['Call-ID'],
              repeat('longreq.one<repeat count=20>really</repeat>longcallid')
            );
          });
        });

        describe('The Via header field', function () {
          it('has 34 values, the last with a long branch', function () {
            for (var i = 0; i < 33; i++) {
              assert.equal(
                parsed.headers.Via[i].by.host,
                'sip' + (33 - i) + '.example.com'
              );
            }

            assert.equal(
              parsed.headers.Via[33].parameters.branch,
              repeat('very<repeat count=50>long</repeat>branchvalue')
            );
          });
        });

        describe('The Contact header field', function () {
          it('has an amazingly long caller name', function () {
            if (parsed) assert.equal(
              repeat('<repeat count=5>amazinglylongcallername</repeat>'),
              parsed.headers.Contact[0].addr.user
            );
          });
        });
      });

      describe('3.1.1.8. Extra Trailing Octets in a UDP Datagram', function () {
        var name = 'dblreq';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('is a REGISTER request (not an INVITE)', function () {
          assert.strictEqual('REGISTER', parsed.Request.Method);
        });
      });

      describe('3.1.1.9. Semicolon-Separated Parameters in URI User Part', function () {
        var name = 'semiuri';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('The Request-URI will parse so that the user part is "user;par=u@example.net".', function () {
          assert.equal('user;par=u@example.net', parsed.Request.URI.user);
        });
      });

      describe('3.1.1.10. Varied and Unknown Transport Types', function () {
        var name = 'transports';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('contains Via header field values with all known transport types and exercises the transport extension mechanism', function () {
          ['UDP', 'SCTP', 'TLS', 'UNKNOWN', 'TCP'].forEach(function (transport, i) {
            assert.equal(
              parsed.headers.Via[i].protocol.transport,
              transport
            );
          });
        });
      });

      describe('3.1.1.11. Multipart MIME Message', function () {
        var name = 'mpart01';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('has a body of length given by the Content-Length header', function () {
          assert.equal(
            parsed.body.length,
            parsed.headers['Content-Length']
          );
        });
      });

      describe('3.1.1.12. Unusual Reason Phrase', function () {
        var name = 'unreason';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('contains unreserved and non-ascii UTF-8 characters', function () {
          if (parsed) assert.equal(
            hex('= 2**3 * 5**2 <hex>D0BDD0BE20D181D182D0BE20D0B4D0B5D0B2D18FD0BDD0BED181D182D0BE20D0B4D0B5D0B2D18FD182D18C202D20D0BFD180D0BED181D182D0BED0B5</hex>'),
            parsed.Status.Reason
          );
        });
      });

      describe('3.1.1.13. Empty Reason Phrase', function () {
        var name = 'noreason';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('contains no reason phrase', function () {
          assert.equal('', parsed.Status.Reason);
        });
      });
    });

    describe('3.1.2. Invalid Messages', function () {
      describe('3.1.2.1. Extraneous Header Field Separators', function () {
        var name = 'badinv01';
        var parsed;
        it('throws /^400 /', function () {
          parsed = assertivelyParse(name, /^400 /);
        });
      });

      describe('3.1.2.2. Content Length Larger Than Message', function () {
        var name = 'clerr';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('has a Content Length that is larger than the actual length of the body', function () {
          assert(parsed.headers['Content-Length'] > parsed.body.length);
        });
      });

      describe('3.1.2.3. Negative Content-Length', function () {
        var name = 'ncl';
        var parsed;
        it('throws /^400 /', function () {
          parsed = assertivelyParse(name, /^400 /);
        });
      });

      describe('3.1.2.4. Request Scalar Fields with Overlarge Values', function () {
        var name = 'scalar02';
        var parsed;
        it('throws /^400 /', function () {
          parsed = assertivelyParse(name, /^400 /);
        });
      });

      describe('3.1.2.5. Response Scalar Fields with Overlarge Values', function () {
        var name = 'scalarlg';
        var parsed;
        //    An element receiving this response will simply discard it.
        it('throws /^400 /', function () {
          parsed = assertivelyParse(name, /^400 /);
        });
      });

      describe('3.1.2.6. Unterminated Quoted String in Display Name', function () {
        var name = 'quotbal';
        var parsed;
        it('throws /^400 /', function () {
          parsed = assertivelyParse(name, /^400 /);
        });
      });

      /*
         It is reasonable always to reject a request with this error with a
         400 Bad Request.  Elements attempting to be liberal with what they
         accept may choose to ignore the brackets.  If the element forwards
         the request, it must not include the brackets in the messages it
         sends.
      */
      describe('3.1.2.7. <> Enclosing Request-URI', function () {
        var name = 'ltgtruri';
        var parsed;
        it('throws /^400 /', function () {
          parsed = assertivelyParse(name, /^400 /);
        });
      });

      describe('3.1.2.8. Malformed SIP Request-URI (embedded LWS)', function () {
        var name = 'lwsruri';
        var parsed;
        it('throws /^400 /', function () {
          parsed = assertivelyParse(name, /^400 /);
        });
      });

      describe('3.1.2.9. Multiple SP Separating Request-Line Elements', function () {
        var name = 'lwsstart';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('does not include the extra SP characters when serializing', function () {
          assert.equal(parsed.Request.serialize(), 'INVITE sip:user@example.com SIP/2.0\r\n');
        });
      });
 
      describe('3.1.2.10. SP Characters at End of Request-Line', function () {
        var name = 'trws';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('does not include the extra SP characters when serializing', function () {
          assert.equal(parsed.Request.serialize(), 'OPTIONS sip:remote-target@example.com SIP/2.0\r\n');
        });
      });

      /*
         An element could choose to be liberal in what it accepts
         and ignore the escaped headers
      */
      describe('3.1.2.11. Escaped Headers in SIP Request-URI', function () {
        var name = 'escruri';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('the SIP Request-URI contains escaped headers', function () {
          assert.equal(parsed.Request.URI.headers.Route, "<sip:example.com>");
        });
      });

      describe('3.1.2.12. Invalid Time Zone in Date Header Field', function () {
        var name = 'baddate';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('contains a non-GMT time zone in the SIP Date header field', function () {
          assert.equal(parsed.headers.Date, "Fri, 01 Jan 2010 16:00:00 EST");
        });
      });

      /*
         An element choosing to be liberal in what it
         accepts could infer the angle brackets since there is no ambiguity in
         this example.  In general, that won't be possible.
      */
      describe('3.1.2.13. Failure to Enclose name-addr URI in <>', function () {
        var name = 'regbadct';
        var parsed;
        it('throws /^400 /', function () {
          parsed = assertivelyParse(name, /^400 /);
        });
      });

      describe('3.1.2.14. Spaces within addr-spec', function () {
        var name = 'badaspec';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('parses the user in the addr-spec in the To header field', function () {
          assert.equal(parsed.headers.To.addr.user, 't.watson');
        });
      });

      describe('3.1.2.15. Non-token Characters in Display Name', function () {
        var name = 'baddn';
        var parsed;
        it('throws /^400 /', function () {
          parsed = assertivelyParse(name, /^400 /);
        });
      });

      describe('3.1.2.16. Unknown Protocol Version', function () {
        var name = 'badvers';
        var parsed;
        it('throws /^505 /', function () {
          parsed = assertivelyParse(name, /^505 /);
        });
      });

      describe('3.1.2.17. Start Line and CSeq Method Mismatch', function () {
        var name = 'mismatch01';
        var parsed;
        it('throws /^400 /', function () {
          parsed = assertivelyParse(name, /^400 /);
        });
      });

      describe('3.1.2.18. Unknown Method with CSeq Method Mismatch', function () {
        var name = 'mismatch02';
        var parsed;
        it('throws /^(501|400) /', function () {
          parsed = assertivelyParse(name, /^(501|400) /);
        });
      });

      /*
         This response has a response code larger than 699.  An element
         receiving this response should simply drop it.
      */
      describe('3.1.2.19. Overlarge Response Code', function () {
        var name = 'bigcode';
        var parsed;
        it('does not parse', function () {
          parsed = assertivelyParse(name, false);
        });
      });
    });
  });

  describe('3.2. Transaction Layer Semantics', function () {
    /*
       This request indicates support for RFC 3261-style transaction
       identifiers by providing the z9hG4bK prefix to the branch parameter,
       but it provides no identifier.  A parser must not break when
       receiving this message.  An element receiving this request could
       reject the request with a 400 Response (preferably statelessly, as
       other requests from the source are likely also to have a malformed
       branch parameter), or it could fall back to the RFC 2543-style
       transaction identifier.
    */
    describe('3.2.1. Missing Transaction Identifier', function () {
      var name = 'badbranch';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});

      it('has Via branch parameter of "z9hG4bK"', function () {
        assert.strictEqual('z9hG4bK', parsed.headers.Via[0].parameters.branch);
      });
    });
  });

  describe('3.3. Application-Layer Semantics', function () {
    describe('3.3.1. Missing Required Header Fields', function () {
      var name = 'insuf';
      var parsed;
      it('throws /^400 /', function () {
        parsed = assertivelyParse(name, /^400 /);
      });
    });

    /*
       This OPTIONS contains an unknown URI scheme in the Request-URI.  A
       parser must accept this as a well-formed SIP request.

       An element receiving this request will reject it with a 416
       Unsupported URI Scheme response.
    */
    describe('3.3.2. Request-URI with Unknown Scheme', function () {
      var name = 'unkscm';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});

      it('contains an unknown URI scheme in the Request-URI', function () {
        assert.equal('nobodyKnowsThisScheme', parsed.Request.URI.scheme);
      });
    });

    /*
       If an element will never accept this scheme as meaningful in a
       Request-URI, it is appropriate to treat it as unknown and return a
       416 Unsupported URI Scheme response.  If the element might accept
       some URIs with this scheme, then a 404 Not Found is appropriate for
       those URIs it doesn't accept.
    */
    describe('3.3.3. Request-URI with Known but Atypical Scheme', function () {
      var name = 'novelsc';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});

      it('contains a Request-URI with an IANA-registered scheme that does not commonly appear in Request-URIs of SIP requests', function () {
        assert.equal('soap.beep', parsed.Request.URI.scheme);
      });
    });

    describe('3.3.4. Unknown URI Schemes in Header Fields', function () {
      var name = 'unksm2';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});

      it('This message contains registered schemes in the To, From, and Contact header fields of a request.', function () {
        assert.strictEqual(parsed.headers.To.addr.scheme, 'isbn');
        assert.strictEqual(parsed.headers.From.addr.scheme, 'http');
        assert.strictEqual(parsed.headers.Contact[0].addr.scheme, 'name');
      });
    });

    describe('3.3.5. Proxy-Require and Require', function () {
      var name = 'bext01';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});
    });

    describe('3.3.6. Unknown Content-Type', function () {
      var name = 'invut';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});

      it('This INVITE request contains a body of unknown type.', function () {
        assert.deepEqual(parsed.headers['Content-Type'],
          {
            "type": "application",
            "subtype": "unknownformat",
            "parameters": {}
          }
        );
      });
    });

    describe('3.3.7. Unknown Authorization Scheme', function () {
      var name = 'regaut01';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});

      it('This REGISTER request contains an Authorization header field with an unknown scheme.', function () {
        assert.strictEqual(parsed.headers.Authorization.other.scheme, 'NoOneKnowsThisScheme');
      });
    });

    describe('3.3.8. Multiple Values in Single Value Required Fields', function () {
      var name = 'multi01';
      var parsed;
      it('throws /^400 /', function () {
        parsed = assertivelyParse(name, /^400 /);
      });
    });

    describe('3.3.9. Multiple Content-Length Values', function () {
      var name = 'mcl01';
      var parsed;
      it('throws /^400 /', function () {
        parsed = assertivelyParse(name, /^400 /);
      });
    });

    describe('3.3.10. 200 OK Response with Broadcast Via Header Field Value', function () {
      var name = 'bcast';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});

      it('This message is a response with a 2nd Via header field value\'s sent-by containing 255.255.255.255.', function () {
        assert.strictEqual(parsed.headers.Via[1].by.host, '255.255.255.255');
      });
    });

    describe('3.3.11. Max-Forwards of Zero', function () {
      var name = 'zeromf';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});

      it('This is a legal SIP request with the Max-Forwards header field value set to zero.', function () {
        assert.equal(parsed.headers['Max-Forwards'], 0);
      });
    });

    describe('3.3.12. REGISTER with a Contact Header Parameter', function () {
      var name = 'cparam01';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});

      it("This register request contains a contact where the 'unknownparam' parameter must be interpreted as a contact-param and not a url-param.", function () {
        assert.strictEqual(parsed.headers.Contact[0].addr.parameters.unknownparam, undefined);
        assert.strictEqual(parsed.headers.Contact[0].parameters.unknownparam, null);
      });
    });

    describe('3.3.13. REGISTER with a url-parameter', function () {
      var name = 'cparam02';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});

      it('This register request contains a contact where the URI has an unknown parameter.', function () {
        assert.strictEqual(parsed.headers.Contact[0].addr.parameters.unknownparam, null);
      });
    });

    describe('3.3.14. REGISTER with a URL Escaped Header', function () {
      var name = 'regescrt';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});

      it('This register request contains a contact where the URI has an escaped header', function () {
        assert.equal(parsed.headers.Contact[0].addr.headers.Route, '<sip:sip.example.com>');
      });
    });

    describe('3.3.15. Unacceptable Accept Offering', function () {
      var name = 'sdp01';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});

      it('This request indicates that the response must contain a body in an unknown type.', function () {
        assert.deepEqual(
          parsed.headers.Accept[0].range,
          {
            "type": "text",
            "subtype": "nobodyKnowsThis",
            "parameters": {}
          }
        );
      });
    });
  });

  describe('3.4. Backward Compatibility', function () {
    describe('3.4.1. INVITE with RFC 2543 Syntax', function () {
      var name = 'inv2543';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});

      it('There is no branch parameter at all on the Via header field value.', function () {
        if (parsed) assert.strictEqual(undefined, parsed.headers.Via[0].parameters.branch);
      });

      it('There is no From tag.', function () {
        if (parsed) assert.strictEqual(undefined, parsed.headers.From.parameters.tag);
      });

      it('There is no explicit Content-Length.', function () {
        if (parsed) assert.strictEqual(undefined, parsed.headers['Content-Length']);
      });

      it('The body is assumed to be all octets in the datagram after the null-line.', function () {
        if (parsed) assert.strictEqual(parsed.body,
          'v=0\r\n' +
          'o=mhandley 29739 7272939 IN IP4 192.0.2.5\r\n' +
          's=-\r\n' +
          'c=IN IP4 192.0.2.5\r\n' +
          't=0 0\r\n' +
          'm=audio 49217 RTP/AVP 0\r\n'
        );
      });

      it('There is no Max-Forwards header field.', function () {
        if (parsed) assert.strictEqual(undefined, parsed.headers['Max-Forwards']);
      });
    });
  });
});
