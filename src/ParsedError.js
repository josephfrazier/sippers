module.exports =
// A ParsedError is thrown when a SIP message could not be completely parsed.
// It contains:
function ParsedError (parsed, statusCode, reasonPhrase) {
  // * the suggested response code
  this.statusCode = statusCode;
  // * the suggested reason phrase
  this.reasonPhrase = reasonPhrase;
  // * the partially [parsed](../index.html#parse) SIP message
  this.parsed = parsed;

  /// adapted from http://stackoverflow.com/a/8460753
  this.name = this.constructor.name;
  // * a human-readable error message
  this.message = statusCode + ' ' + reasonPhrase;
  this.toString = function () {return this.message;};
  this.constructor.prototype.__proto__ = Error.prototype;
  Error.captureStackTrace(this, this.constructor);
}
