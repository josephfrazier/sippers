// sippers
// =======

/// Use a formal grammar parser generated by [PEG.js](https://github.com/dmajda/pegjs)
var grammar = require('./dist/grammar');

/// Combine headers as in [RFC 3261 Section 7.3](http://tools.ietf.org/html/rfc3261#section-7.3)
var combineHeaders = require('./dist/helpers').mapList.bind(null, true);

// Parses (a component of) a SIP message from its textual representation into a plain object
//
// @static
// @method <a id="parse" href="#parse">parse</a>
//
// @param {String} input
// @param {String or Object} [options]
//   If it's absent, it's treated like "SIP_message".
//   If it's a String, it's treated like `options.startRule`.
// @param {String} options.startRule
//   the name of the rule to start parsing from
//
// @return {Object}
//   a JSON [parse tree](http://en.wikipedia.org/wiki/Parse_tree) loosely
//   corresponding to the [SIP ABNF](http://tools.ietf.org/html/rfc3261#section-25)
//
// @throws {[SyntaxError](#SyntaxError)}
//   if the text could not be parsed as an `options.startRule`
// @throws {[ParsedError](#ParsedError)}
//   if the SIP message could not be completely parsed or is semantically invalid

module.exports.parse = function parse (input, options) {
  /// allow startRule to be passed as string, default to SIP_message
  options = options || 'SIP_message';
  if (options.constructor === String) {
    options = {startRule: options};
  }

  /// http://tools.ietf.org/html/rfc3261#section-7.5
  /// Implementations processing SIP messages over stream-oriented transports
  /// MUST ignore any CRLF appearing before the start-line
  input = input.replace(/(\r\n)*/, '');

  input = unfoldLWS(input);

  try {
    var parsed = grammar.parse(input, options);
  } catch (e) {
    /// add debugging info
    e.message += [
      ' at line', e.line,
      'column', e.column,
      'of (LWS unfolded):\n\n<< EOM', '\n' + input + 'EOM'
    ].join(' ');

    throw e;
  }

  if (options.startRule === 'SIP_message') {
    try {
      parsed.headers = combineHeaders(parsed.headers);
    } catch (e) {
      throw new ParsedError(parsed, 400, "Multiple " + e.message + " values");
    }

    checkStartLine(parsed);

    if (parsed.Request) {
      mandateRequestHeaders(parsed);
      checkCSeqMethod(parsed);
    }

    checkCSeqRange(parsed);
    mandateHeader(parsed, 'Content-Length', true);
    mandateHeader(parsed, 'Contact', true);
  }

  return parsed;
}

// Unfold linear white space according to [RFC 3261 Section 25.1](http://tools.ietf.org/html/rfc3261#section-25.1)
// @static
// @method unfoldLWS
var unfoldLWS = module.exports.unfoldLWS = function unfoldLWS (input) {
  var emptyLine = '\r\n\r\n';
  var hadEmptyLine = input.indexOf(emptyLine) > -1;
  var folding = /[\t ]*\r\n[\t ]+/g;
  var headersBody = input.split(emptyLine);
  var headers = headersBody[0].replace(folding, ' ');
  var body = headersBody.slice(1).join(emptyLine);
  return headers + (hadEmptyLine ? emptyLine : '') + body;
}

// See the [PEG.js documentation](https://github.com/dmajda/pegjs#using-the-parser).
// @static
// @property <a id="SyntaxError" href="#SyntaxError">SyntaxError</a>
module.exports.SyntaxError = grammar.SyntaxError;

// See [ParsedError](src/ParsedError.html)
// @static
// @module <a id="ParsedError" href="#ParsedError">ParsedError</a>
var ParsedError = module.exports.ParsedError = require('./dist/ParsedError')

/// RFC 3261 Section 8.1.1 (http://tools.ietf.org/html/rfc3261#section-8.1.1):
/// A valid SIP request formulated by a UAC MUST, at a minimum, contain
/// the following header fields: To, From, CSeq, Call-ID, Max-Forwards, and Via;
/// all of these header fields are mandatory in all SIP requests
function mandateRequestHeaders (parsed) {
  return mandateHeaders(parsed, ['To', 'From', 'CSeq', 'Call-ID', 'Max-Forwards', 'Via']);
}

function mandateHeaders (parsed, headers) {
  headers.forEach(mandateHeader.bind(null, parsed));
}

function mandateHeader (parsed, headerName, optional) {
  var headerValue = parsed.headers[headerName];
  var reasonPrefix;
  if (!headerValue && !optional) {
    reasonPrefix = 'Missing';
  }
  else if (headerValue && headerValue.$isExtension) {
    reasonPrefix = 'Malformed';
  }
  if (reasonPrefix) {
    var reasonPhrase = [reasonPrefix, headerName, 'header'].join(' ');
    throw new ParsedError(parsed, 400, reasonPhrase);
  }
  return parsed;
}

function checkCSeqRange (parsed) {
  if (parsed.headers.CSeq.number >= Math.pow(2, 32)) {
    throw new ParsedError(parsed, 400, 'Invalid CSeq sequence number');
  }
}

function checkCSeqMethod (parsed) {
  if (parsed.Request.Method != parsed.headers.CSeq.method) {
    throw new ParsedError(parsed, 400, 'CSeq Method does not match Request Method');
  }
}

function checkStartLine (parsed) {
  if (parsed.start_line) {
    throw new ParsedError(parsed, 400, 'Malformed start-line');
  }
  /// check SIP version
  else if ((parsed.Request || parsed.Status).Version != "SIP/2.0") {
    throw new ParsedError(parsed, 505, 'Version Not Supported');
  }
}
