var grammar = require('./grammar');

function parse (input, options){
  // allow startRule to be passed as string, default to SIP_message
  options = options || 'SIP_message';
  if (options.constructor === String) {
    options = {startRule: options};
  }

  input = foldLWS(input);

  try {
    return grammar.parse(input, options);
  } catch (e) {
    // add debugging info
    e.message += [
      ' at line', e.line,
      'column', e.column,
      'of (LWS folded):\n\n<< EOM', '\n' + input + 'EOM'
    ].join(' ');

    throw e;
  }
}

// RFC 3261 25.1:
// All linear white space, including folding, has the same semantics as SP.
function foldLWS (input) {
  var emptyLine = '\r\n\r\n';
  var hadEmptyLine = input.indexOf(emptyLine) > -1;
  var folding = /[\t ]*\r\n[\t ]+/g;
  var headersBody = input.split(emptyLine, 2);
  var headers = headersBody[0].replace(folding, ' ');
  var body = headersBody[1] || '';
  return headers + (hadEmptyLine ? emptyLine : '') + body;
}

module.exports = {
  SyntaxError: grammar.SyntaxError,
  parse: parse,
  foldLWS: foldLWS
};