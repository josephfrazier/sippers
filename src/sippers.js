var grammar = require('./grammar');

// See RFC 3261 Section 7.3
var combineHeaders = require('./helpers').mapList.bind(null, true);

function parse (input, options){
  // allow startRule to be passed as string, default to SIP_message
  options = options || 'SIP_message';
  if (options.constructor === String) {
    options = {startRule: options};
  }

  // http://tools.ietf.org/html/rfc3261#section-7.5
  // Implementations processing SIP messages over stream-oriented transports
  // MUST ignore any CRLF appearing before the start-line
  input = input.replace(/(\r\n)*/, '');

  input = foldLWS(input);

  try {
    var parsed = grammar.parse(input, options);
  } catch (e) {
    // add debugging info
    e.message += [
      ' at line', e.line,
      'column', e.column,
      'of (LWS folded):\n\n<< EOM', '\n' + input + 'EOM'
    ].join(' ');

    throw e;
  }

  if (options.startRule === 'SIP_message') {
    try {
      parsed.headers = combineHeaders(parsed.headers);
    } catch (e) {
      throw new ParsedError(parsed, 400, "Multiple " + e.message + " values");
    }

    if (parsed.Request) {
      mandateRequestHeaders(parsed);
      checkCSeqMethod(parsed);
    }

    checkCSeqRange(parsed);
    checkSIPVersion(parsed);
    mandateHeader(parsed, 'Content-Length', true);
  }

  return parsed;
}

// RFC 3261 25.1:
// All linear white space, including folding, has the same semantics as SP.
function foldLWS (input) {
  var emptyLine = '\r\n\r\n';
  var hadEmptyLine = input.indexOf(emptyLine) > -1;
  var folding = /[\t ]*\r\n[\t ]+/g;
  var headersBody = input.split(emptyLine);
  var headers = headersBody[0].replace(folding, ' ');
  var body = headersBody.slice(1).join(emptyLine);
  return headers + (hadEmptyLine ? emptyLine : '') + body;
}

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

function checkSIPVersion (parsed) {
  if ((parsed.Request || parsed.Status).Version != "SIP/2.0") {
    throw new ParsedError(parsed, 505, 'Version Not Supported');
  }
}

// adapted from http://stackoverflow.com/a/8460753
function ParsedError (parsed, statusCode, reasonPhrase) {
  this.statusCode = statusCode;
  this.reasonPhrase = reasonPhrase;
  this.parsed = parsed;

  this.name = this.constructor.name;
  this.message = statusCode + ' ' + reasonPhrase;
  this.toString = function () {return this.message;};
  this.constructor.prototype.__proto__ = Error.prototype;
  Error.captureStackTrace(this, this.constructor);
}

module.exports = {
  SyntaxError: grammar.SyntaxError,
  parse: parse,
  foldLWS: foldLWS,
  ParsedError: ParsedError
};
