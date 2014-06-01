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

        it('has a CSeq number of 9', function () {
          assert.equal(9, parsed ? parsed.headers.CSeq.sequenceNumber : 9);
        });

        it('has a Max-Forwards of 68', function () {
          assert.equal(68, parsed ? parsed.headers['Max-Forwards'] : 68);
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
          assert.equal('sips:user@example.com', parsed.Request_Line.URI.userinfo.user);
        });

        it('The From and To URIs have escaped characters in their userparts.', function () {
          assert.equal('I have spaces', parsed.headers.From.addr.userinfo.user);
          assert.equal('user', parsed.headers.To.addr.userinfo.user);
        });

        it('The Contact URI has escaped characters in the URI parameters.', function () {
          assert.deepEqual(
            jsonClone(parsed.headers.Contact[0].addr.params),
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
          assert.equal('null-\u0000-null', parsed.headers.From.addr.userinfo.user);
          assert.equal('null-\u0000-null', parsed.headers.To.addr.userinfo.user);
        });

        it('has first Contact user of "%00"', function () {
          assert.equal('\u0000', parsed.headers.Contact[0].addr.userinfo.user);
        });

        it('has second Contact user of "%00%00"', function () {
          assert.equal('\u0000\u0000', parsed.headers.Contact[1].addr.userinfo.user);
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
          assert.strictEqual('RE%47IST%45R', parsed.Request_Line.Method);
        });

        it('The display name portion of the To and From header fields is "%Z%45".', function () {
          assert.equal('%Z%45', parsed.headers.To.addr.display_name);
          assert.equal('%Z%45', parsed.headers.From.addr.display_name);
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
      });

      describe('3.1.1.7. Long Values in Header Fields', function () {
        var name = 'longreq';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});
      });

      describe('3.1.1.8. Extra Trailing Octets in a UDP Datagram', function () {
        var name = 'dblreq';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

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

        it('round-trips', function () {roundTrip(parsed);});

        it('The Request-URI will parse so that the user part is "user;par=u@example.net".', function () {
          assert.equal('user;par=u@example.net', parsed.Request_Line.URI.userinfo.user);
        });
      });

      describe('3.1.1.10. Varied and Unknown Transport Types', function () {
        var name = 'semiuri';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});
      });

      describe('3.1.1.11. Multipart MIME Message', function () {
        var name = 'mpart01';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});
      });

      describe('3.1.1.12. Unusual Reason Phrase', function () {
        var name = 'unreason';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});
      });

      describe('3.1.1.13. Empty Reason Phrase', function () {
        var name = 'noreason';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('contains no reason phrase', function () {
          assert.equal('', parsed.Status_Line.Reason_Phrase);
        });
      });
    });

    describe('3.1.2. Invalid Messages', function () {
      describe('3.1.2.1. Extraneous Header Field Separators', function () {
        var name = 'badinv01';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});
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
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('This request has a negative value for Content-Length.', function () {
          assert.strictEqual('-999', parsed.headers['Content-Length']);
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
        it('throws /^400 /', function () {
          parsed = assertivelyParse(name, /^400 /);
        });
      });

      describe('3.1.2.6. Unterminated Quoted String in Display Name', function () {
        var name = 'quotbal';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('has an unterminated quote in the display name of the To field', function () {
          assert.strictEqual(parsed.headers.To, '"Mr. J. User <sip:j.user@example.com>');
        });
      });

      describe('3.1.2.7. <> Enclosing Request-URI', function () {
        var name = 'ltgtruri';
        var parsed;
        it('does not parse', function () {
          parsed = assertivelyParse(name, false);
        });
      });

      describe('3.1.2.8. Malformed SIP Request-URI (embedded LWS)', function () {
        var name = 'lwsruri';
        var parsed;
        it('does not parse', function () {
          parsed = assertivelyParse(name, false);
        });
      });

      describe('3.1.2.9. Multiple SP Separating Request-Line Elements', function () {
        var name = 'lwsstart';
        var parsed;
        it('does not parse', function () {
          parsed = assertivelyParse(name, false);
        });
      });
 
      describe('3.1.2.10. SP Characters at End of Request-Line', function () {
        var name = 'trws';
        var parsed;
        it('does not parse', function () {
          parsed = assertivelyParse(name, false);
        });
      });

      describe('3.1.2.11. Escaped Headers in SIP Request-URI', function () {
        var name = 'escruri';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('the SIP Request-URI contains escaped headers', function () {
          assert.equal(parsed.Request_Line.URI.headers.Route, "<sip:example.com>");
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
          assert.strictEqual(parsed.headers.Date, "Fri, 01 Jan 2010 16:00:00 EST");
        });
      });

      describe('3.1.2.13. Failure to Enclose name-addr URI in <>', function () {
        var name = 'regbadct';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('The SIP URI contained in the Contact Header field has an escaped header', function () {
          assert.equal(parsed.headers.Contact[0].addr.headers.Route, "<sip:sip.example.com>");
        });
      });

      describe('3.1.2.14. Spaces within addr-spec', function () {
        var name = 'badaspec';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('the addr-spec in the To header field contains spaces', function () {
          assert.strictEqual(parsed.headers.To, '"Watson, Thomas" < sip:t.watson@example.org >');
        });
      });

      describe('3.1.2.15. Non-token Characters in Display Name', function () {
        var name = 'baddn';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});
      });

      describe('3.1.2.16. Unknown Protocol Version', function () {
        var name = 'badvers';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('has version number 7.0', function () {
          assert.strictEqual(parsed.Request_Line.SIP_Version, 'SIP/7.0');
        });
      });

      describe('3.1.2.17. Start Line and CSeq Method Mismatch', function () {
        var name = 'mismatch01';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('This request has mismatching values for the method in the start line and the CSeq header field.', function () {
          assert.strictEqual('OPTIONS', parsed.Request_Line.Method);
          assert.strictEqual('INVITE', parsed.headers.CSeq.requestMethod);
        });
      });

      describe('3.1.2.18. Unknown Method with CSeq Method Mismatch', function () {
        var name = 'mismatch02';
        var parsed;
        it('parses', function () {
          parsed = assertivelyParse(name);
        });

        it('round-trips', function () {roundTrip(parsed);});

        it('This request has mismatching values for the method in the start line and the CSeq header field.', function () {
          assert.strictEqual('NEWMETHOD', parsed.Request_Line.Method);
          assert.strictEqual('INVITE', parsed.headers.CSeq.requestMethod);
        });
      });

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
    describe('3.2.1. Missing Transaction Identifier', function () {
      var name = 'badbranch';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});

      it('has Via branch parameter of "z9hG4bK"', function () {
        assert.strictEqual('z9hG4bK', parsed.headers.Via[0].params.branch);
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

      it('round-trips', function () {roundTrip(parsed);});
    });

    describe('3.3.2. Request-URI with Unknown Scheme', function () {
      var name = 'unkscm';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});

      it('This OPTIONS contains an unknown URI scheme in the Request-URI.', function () {
        assert.strictEqual(parsed.Request_Line.URI.scheme, 'nobodyKnowsThisScheme');
      });
    });

    describe('3.3.3. Request-URI with Known but Atypical Scheme', function () {
      var name = 'novelsc';
      var parsed;
      it('parses', function () {
        parsed = assertivelyParse(name);
      });

      it('round-trips', function () {roundTrip(parsed);});

      it('This OPTIONS contains an Request-URI with an IANA-registered scheme that does not commonly appear in Request-URIs of SIP requests.', function () {
        assert.strictEqual(parsed.Request_Line.URI.scheme, 'soap.beep');
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
            "m_type": "application",
            "m_subtype": "unknownformat",
            "m_parameters": {}
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
        assert.strictEqual(parsed.headers.Authorization.other_response.auth_scheme, 'NoOneKnowsThisScheme');
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
        assert.strictEqual(parsed.headers.Via[1].sent_by.host, '255.255.255.255');
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
        assert.strictEqual(parsed.headers.Contact[0].addr.params.unknownparam, undefined);
        assert.strictEqual(parsed.headers.Contact[0].params.unknownparam, null);
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
        assert.strictEqual(parsed.headers.Contact[0].addr.params.unknownparam, null);
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
          parsed.headers.Accept[0].media_range,
          {
            "m_type": "text",
            "m_subtype": "nobodyKnowsThis",
            "m_parameters": {}
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
        if (parsed) assert.strictEqual(undefined, parsed.headers.Via[0].params.branch);
      });

      it('There is no From tag.', function () {
        if (parsed) assert.strictEqual(undefined, parsed.headers.From.params.tag);
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
