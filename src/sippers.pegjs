{
  function mapList (isHeaders, list, serializeOptions) {
    var combined = list.reduce(
      function combine (map, item) {
        var name = item.name;
        var value = item.value;
        if (isHeaders && Array.isArray(value)) {
          value = (map[name] || []).concat(value);
        }
        map[name] = value;
        return map;
      },
      {}
    );

    Object.defineProperty(combined, 'serialize', {
      value: function (isHeaders, options) {
        options = options || {};
        var separator = options.separator;
        var prepend = options.prepend;

        var keySerialize = function (name) {
          // cast to array
          var values = [].concat(this[name]);
          values = values.map(function(i){return serialize(i);});
          if (isHeaders) {
            var headerSep = name === 'User-Agent' ? ' ' : ', ';
            var joined = values.join(headerSep);
            if (joined.length > 0) {
              joined = ' ' + joined;
            }
            return name + ':' + joined + '\r\n';
          }
          else {
            return (separator || ';') + name + (values[0] ? '=' + values[0] : '');
          }
        }.bind(this);

        var serialized = Object.keys(this).map(keySerialize).join('');
        if (separator) {
          serialized = serialized.slice(separator.length);
        }
        if (prepend) {
          serialized = prepend + serialized;
        }
        return serialized;
      }.bind(combined, isHeaders, serializeOptions)
    });

    return combined;
  }

  // See RFC 3261 Section 7.3
  var combineHeaders = mapList.bind(null, true);
  // non-RFC, just convenient
  var combineParams = mapList.bind(null, false);

  function serialize (obj, options) {
    options = options || {};
    var prefix = options.prefix || '';
    var separator = options.separator || '';
    var suffix = options.suffix || '';
    var transform = options.transform || function(i){return i;};
    var serialized = '';
    if (obj) {
      if (Array.isArray(obj)) {
        serialized = obj
          // jshint eqnull:true
          .filter(function(i){return i != null;})
          .map(function(i){return serialize(i);})
          .join(separator);
      }
      else if (obj.serialize) {
        serialized = obj.serialize();
      }
      else {
        serialized = obj + '';
      }
    }
    return transform(serialized + suffix);
  }

  function sipuriBuild (scheme, userinfo, hostport, uri_parameters, headers) {
    return defineSerialize({
        scheme: scheme
      , userinfo: userinfo
      , hostport: hostport
      , uri_parameters: uri_parameters
      , headers: headers
    }, ['scheme', ':', 'userinfo', 'hostport', 'uri_parameters', 'headers'], {
      transform: function (addrSpecString) {
        if (this.display_name || this._isNameAddr) {
          addrSpecString = serialize(this.display_name) + '<' + addrSpecString + '>';
        }
        return addrSpecString;
      }
    });
  }

  function defineSerialize (obj, propertyList, options) {
    options = options || {};
    options.transform = (options.transform || function(i){return i;}).bind(obj);
    return Object.defineProperty(obj, 'serialize', {value:
      function (propertyList, options) {
        function getProperty (property) {
          if (property in this) {
            return this[property];
          }
          return property;
        }
        return serialize(propertyList.map(getProperty.bind(this)), options);
      }.bind(obj, propertyList, options)
    });
  }

  function hostportBuild (host, port) {
    return defineSerialize({
      host: host,
      port: port
    }, ['host', 'port'], {separator: ':'});
  }

  function xparamsBuild (prop, propName, params, paramsName, combineOptions) {
    paramsName = paramsName || 'params';
    var ret = {};
    ret[propName] = prop;
    ret[paramsName] = combineParams(params, combineOptions);
    return defineSerialize(ret, [propName, paramsName]);
  }

  function addrparamsBuild (addr, params) {
    return xparamsBuild(addr, 'addr', params, 'params');
  }

  function ret (val) {return function (val) {
    return val;
  }.bind(null, val);}

  function defineObject (type, value, serialized) {
    return Object.defineProperties(new type(value), {
      valueOf: {value: ret(value)},
      serialize: {value: ret(serialized)}
    });
  }

  var defineDelimited = defineObject.bind(null, String);

  function joinEscaped (chars) {
    var value = chars.join('');
    var serialized = serialize(chars);
    return defineDelimited(value, serialized);
  }

  // adapted from http://stackoverflow.com/a/1685917
  function toFixed(x) {
    var e;
    if (Math.abs(x) < 1.0) {
      e = parseInt(x.toString().split('e-')[1]);
      if (e) {
          x *= Math.pow(10,e-1);
          x = '0.' + (new Array(e)).join('0') + x.toString().substring(2);
      }
    } else {
      e = parseInt(x.toString().split('+')[1]);
      if (e > 20) {
          e -= 20;
          x /= Math.pow(10,e);
          x += (new Array(e+1)).join('0');
      }
    }
    return x;
  }

  function padInt (text, width) {
    var value = parseInt(text, 10);
    var serialized;
    if (width) {
      serialized = ('0000' + value).slice(-width);
    }
    else {
      serialized = toFixed(value);
    }
    return defineObject(Number, value, serialized);
  }
}

// begin RFC 2234
// http://tools.ietf.org/html/rfc2234#section-6.1
ALPHA          =  [A-Z] / [a-z]
BIT            =  "0" / "1"
CHAR           =  [\x01-\x7F] // any 7-bit US-ASCII character, excluding NUL
CR             =  "\r" // carriage return
CRLF           =  $ CR LF // Internet standard newline
CTL            =  [\x00-\x1F] / "\x7F" // controls
DIGIT          =  [0-9] // 0-9
_PDIGITS       =  DIGIT+ {return padInt(text());}
_PDIGIT2       =  DIGIT DIGIT {return padInt(text(), 2);}
_PDIGIT3       =  DIGIT DIGIT DIGIT {return padInt(text(), 3);}
_PDIGIT4       =  DIGIT DIGIT DIGIT DIGIT {return padInt(text(), 4);}
DQUOTE         =  "\"" // " (Double Quote)
HEXDIG         =  DIGIT / "A" / "B" / "C" / "D" / "E" / "F"
HTAB           =  "\t" // horizontal tab
LF             =  "\n" // linefeed
LWSP           =  $ (WSP / CRLF WSP)* // linear white space (past newline)
OCTET          =  [\x00-\xFF] // 8 bits of data
SP             =  " " // space
VCHAR          =  [\x21-\x7E] // visible (printing) characters
WSP            =  SP / HTAB // white space
// end RFC 2234

// http://tools.ietf.org/html/rfc3261#page-219

alphanum  =  ALPHA / DIGIT

// http://tools.ietf.org/html/rfc3261#page-220

reserved    =  ";" / "/" / "?" / ":" / "@" / "&" / "=" / "+"
               / "$" / ","
unreserved  =  alphanum / mark
mark        =  "-" / "_" / "." / "!" / "~" / "*" / "'"
               / "(" / ")"
escaped     =  "%" HEXDIG HEXDIG
               {
                 var decoded = decodeURIComponent(text());
                 return defineDelimited(decoded, text());
               }

/* RFC3261 25: A recipient MAY replace any linear white space with a single SP
 * before interpreting the field value or forwarding the message downstream
 */
LWS  =  (WSP* CRLF)? WSP+ {return ' ';} // linear whitespace
SWS  =  $ LWS? // sep whitespace

HCOLON  =  ( SP / HTAB )* ":" SWS {return ':';}

TEXT_UTF8_TRIM  =  $( TEXT_UTF8char+ (LWS* TEXT_UTF8char)* )
TEXT_UTF8char   =  $( [\x21-\x7E] / UTF8_NONASCII )
UTF8_NONASCII   =  $( [\xC0-\xDF] UTF8_CONT
                /  [\xE0-\xEF] UTF8_CONT UTF8_CONT
                /  [\xF0-\xF7] UTF8_CONT UTF8_CONT UTF8_CONT
                /  [\xF8-\xFb] UTF8_CONT UTF8_CONT UTF8_CONT UTF8_CONT
                /  [\xFC-\xFD] UTF8_CONT UTF8_CONT UTF8_CONT UTF8_CONT UTF8_CONT )
UTF8_CONT       =  [\x80-\xBF]

// http://tools.ietf.org/html/rfc3261#page-221
LHEX  =  DIGIT / [\x61-\x66] // lowercase a-f

token       =  $( (alphanum / "-" / "." / "!" / "%" / "*"
               / "_" / "+" / "`" / "'" / "~" )+ )
separators  =  "(" / ")" / "<" / ">" / "@" /
               "," / ";" / ":" / "\\" / DQUOTE /
               "/" / "[" / "]" / "?" / "=" /
               "{" / "}" / SP / HTAB
word        =  $( (alphanum / "-" / "." / "!" / "%" / "*" /
               "_" / "+" / "`" / "'" / "~" /
               "(" / ")" / "<" / ">" /
               ":" / "\\" / DQUOTE /
               "/" / "[" / "]" / "?" /
               "{" / "}" )+ )

STAR    =  SWS "*" SWS {return '*';} // asterisk
SLASH   =  SWS "/" SWS {return '/';} // slash
EQUAL   =  SWS "=" SWS {return '=';} // equal
LPAREN  =  SWS "(" SWS {return '(';} // left parenthesis
RPAREN  =  SWS ")" SWS {return ')';} // right parenthesis
RAQUOT  =  ">" SWS     {return '>';} // right angle quote
LAQUOT  =  SWS "<"     {return '<';} // left angle quote
COMMA   =  SWS "," SWS {return ',';} // comma
SEMI    =  SWS ";" SWS {return ';';} // semicolon
COLON   =  SWS ":" SWS {return ':';} // colon
LDQUOT  =  SWS DQUOTE  {return '"';}// open double quotation mark
RDQUOT  =  DQUOTE SWS  {return '"';}// close double quotation mark

// http://tools.ietf.org/html/rfc3261#page-222
comment  =  LPAREN value:$((ctext / quoted_pair / comment)*) RPAREN
            {
              return defineDelimited(value, '(' + value + ')');
            }
ctext    =  [\x21-\x27] / [\x2A-\x5B] / [\x5D-\x7E] / UTF8_NONASCII
            / LWS


quoted_string  =  SWS DQUOTE value:$((qdtext / quoted_pair )*) DQUOTE
                  {
                    return defineDelimited(value, '"' + value + '"');
                  }
qdtext         =  LWS / "\x21" / [\x23-\x5B] / [\x5D-\x7E]
                  / UTF8_NONASCII

quoted_pair  =  "\\" ([\x00-\x09] / [\x0B-\x0C]
                / [\x0E-\x7F])

/*
   The BNF for telephone_subscriber can be found in RFC 2806 [9].  Note,
   however, that any characters allowed there that are not allowed in
   the user part of the SIP URI MUST be escaped.
*/

SIP_URI          =  "sip:" userinfo:( userinfo )? hostport:hostport
                    uri_parameters:uri_parameters headers:( headers )?
                    {
                      return sipuriBuild('sip', userinfo, hostport, uri_parameters, headers);
                    }

SIPS_URI          =  "sips:" userinfo:( userinfo )? hostport:hostport
                     uri_parameters:uri_parameters headers:( headers )?
                     {
                       return sipuriBuild('sip', userinfo, hostport, uri_parameters, headers);
                    }

//TODO telephone_subscriber
//userinfo         =  ( user / telephone_subscriber ) ( ":" password )? "@"
userinfo         =  user:( user ) password:( ":" p:password {return p;} )? "@"
                    {
                      return defineSerialize({
                        user: user,
                        password: password
                      }, ['user', 'password'], {
                        separator: ':',
                        suffix: '@'
                      });
                    }
user             =  chars:( unreserved / escaped / user_unreserved )+
                    {return joinEscaped(chars);}

user_unreserved  =  "&" / "=" / "+" / "$" / "," / ";" / "?" / "/"
password         =  chars:( unreserved / escaped /
                    "&" / "=" / "+" / "$" / "," )*
                    {return joinEscaped(chars);}

hostport         =  host:host port:( ":" p:port {return p;} )?
                    {
                      return hostportBuild(host, port);
                    }
host             =  $( hostname / IPv4address / IPv6reference )
hostname         =  ( domainlabel "." )* toplabel ( "." )?
// TODO find out why these don't work and confirm that the alternatives are equivalent
//domainlabel      =  alphanum / alphanum ( alphanum / "-" )* alphanum
  domainlabel      =  alphanum+ ( "-"+ alphanum+ )*
//toplabel         =  ALPHA / ALPHA ( alphanum / "-" )* alphanum
  toplabel         =  ALPHA alphanum* ( "-"+ alphanum+ )*

// http://tools.ietf.org/html/rfc3261#page-223

// begin RFC 5954 (redefines IPv4address and IPv6address)
// http://tools.ietf.org/html/rfc5954#section-4.1
// rules copied from https://github.com/for-GET/core-pegjs/blob/80baf4a0ee0f5f332dfaeea1353daec857f9aee3/src/ietf/rfc3986-uri.pegjs#L102-L136
IPv6address
  = $(                                                            h16_ h16_ h16_ h16_ h16_ h16_ ls32
     /                                                       "::"      h16_ h16_ h16_ h16_ h16_ ls32
     / (                                               h16)? "::"           h16_ h16_ h16_ h16_ ls32
     / (                               h16_?           h16)? "::"                h16_ h16_ h16_ ls32
     / (                         (h16_ h16_?)?         h16)? "::"                     h16_ h16_ ls32
     / (                   (h16_ (h16_ h16_?)?)?       h16)? "::"                          h16_ ls32
     / (             (h16_ (h16_ (h16_ h16_?)?)?)?     h16)? "::"                               ls32
     / (       (h16_ (h16_ (h16_ (h16_ h16_?)?)?)?)?   h16)? "::"                               h16
     / ( (h16_ (h16_ (h16_ (h16_ (h16_ h16_?)?)?)?)?)? h16)? "::"
     )

ls32
  // least_significant 32 bits of address
  = h16 ":" h16
  / IPv4address

h16_
  = h16 ":"

h16
  // 16 bits of address represented in hexadecimal
  = $(HEXDIG (HEXDIG (HEXDIG HEXDIG?)?)?)

IPv4address
  = $(dec_octet "." dec_octet "." dec_octet "." dec_octet)

// CHANGE order in reverse for greedy matching
dec_octet
  = $( "25" [\x30-\x35]      // 250-255
     / "2" [\x30-\x34] DIGIT // 200-249
     / "1" DIGIT DIGIT       // 100-199
     / [\x31-\x39] DIGIT     // 10-99
     / DIGIT                 // 0-9
     )
// end RFC 5954

IPv6reference  =  "[" IPv6address "]"
hexpart        =  hexseq / hexseq "::" ( hexseq )? / "::" ( hexseq )?
hexseq         =  hex4 ( ":" hex4)*
hex4           =  HEXDIG HEXDIG? HEXDIG? HEXDIG?
port           =  _PDIGITS

uri_parameters    =  parameters:( ";" up:uri_parameter {return up;})*
                     { return combineParams(parameters); }
uri_parameter     =  transport_param / user_param / method_param
                     / ttl_param / maddr_param / lr_param / other_param

// begin RFC 7118 (augments transport & transport_param)
// http://tools.ietf.org/html/rfc7118
transport_param   =  "transport="
                     value:( "udp" / "tcp" / "sctp" / "tls"
                     / "wss" / "ws"
                     / other_transport)
                     { return {name: 'transport', value: value}; }
// end RFC 7118

other_transport   =  token

user_param        =  "user=" value:( "phone" / "ip" / other_user)
                     { return {name: 'user', value: value}; }
other_user        =  token

method_param      =  "method=" value:Method
                     { return {name: 'method', value: value}; }
ttl_param         =  "ttl=" value:ttl
                     { return {name: 'ttl', value: value}; }
maddr_param       =  "maddr=" value:host
                     { return {name: 'maddr', value: value}; }
lr_param          =  "lr" {return {name: 'lr', value: null }; }
other_param       =  name:pname value:( "=" v:pvalue {return v;} )?
                     {return {name: name, value: value};}
pname             =  _paramchars
pvalue            =  _paramchars
_paramchars       =  chars:paramchar+ {return joinEscaped(chars);}
paramchar         =  param_unreserved / unreserved / escaped
param_unreserved  =  "[" / "]" / "/" / ":" / "&" / "+" / "$"

headers         =  "?" first:header rest:( "&" h:header {return h;} )*
                   {
                     return combineParams([first].concat(rest), {
                       separator: '&',
                       prepend: '?'
                     });
                   }
header          =  name:hname "=" value:hvalue
                   {return {name: name, value: value};}
hname           =  chars:_hchar+ {return joinEscaped(chars);}
hvalue          =  chars:_hchar* {return joinEscaped(chars);}
_hchar          =  hnv_unreserved / unreserved / escaped
hnv_unreserved  =  "[" / "]" / "/" / "?" / ":" / "+" / "$"

SIP_message    =  Request / Response

Request        =  Request_Line:Request_Line
                  message_headers:_message_headers
                  CRLF
                  message_body:( message_body )?
                  {
                    return defineSerialize({
                      Request_Line: Request_Line,
                      message_headers: message_headers,
                      message_body: message_body
                    }, ['Request_Line', 'message_headers', '\r\n', 'message_body']);
                  }

Request_Line   =  Method:Method SP Request_URI:Request_URI SP SIP_Version:SIP_Version CRLF
                  {
                    return defineSerialize({
                      Method: Method,
                      Request_URI: Request_URI,
                      SIP_Version: SIP_Version
                    }, ['Method', 'Request_URI', 'SIP_Version'], {
                      separator: ' ',
                      suffix: '\r\n'
                    });
                  }

Request_URI    =  SIP_URI / SIPS_URI / absoluteURI
absoluteURI    =  scheme:scheme ":" part:( hier_part / opaque_part )
                  {
                    return defineSerialize({
                      scheme: scheme,
                      part: part
                    }, ['scheme', 'part'], {separator: ':'});
                  }

hier_part      =  path:( net_path / abs_path ) query:( "?" q:query {return q;} )?
                  {
                    return defineSerialize({
                      path: path,
                      query: query
                    }, ['path', 'query'], {separator: '?'});
                  }

net_path       =  "//" authority:authority abs_path:( abs_path )?
                  {
                    return defineSerialize({
                      authority: authority,
                      abs_path: abs_path
                    }, ['//', 'authority', 'abs_path']);
                  }
abs_path       =  "/" path_segments:path_segments {return path_segments;}

// http://tools.ietf.org/html/rfc3261#page-224
opaque_part    =  ns:uric_no_slash chars:uric*
                  {return joinEscaped([ns].concat(chars));}
uric           =  reserved / unreserved / escaped
uric_no_slash  =  unreserved / escaped / ";" / "?" / ":" / "@"
                  / "&" / "=" / "+" / "$" / ","
path_segments  =  first:segment rest:( "/" s:segment {return s;} )*
                  { return [first].concat(rest); }
segment        =  value:_pchars
                  params:( ";" p:param {return p;} )*
                  {
                    return xparamsBuild(value, 'value', params);
                  }
param          =  _pchars
_pchars        =  chars:pchar* {return joinEscaped(chars);}
pchar          =  unreserved / escaped /
                  ":" / "@" / "&" / "=" / "+" / "$" / ","
scheme         =  $( ALPHA ( ALPHA / DIGIT / "+" / "-" / "." )* )
authority      =  srvr / reg_name

srvr           =  (
                    userinfo:userinfo?
                    hostport: hostport
                    {
                      return defineSerialize({
                        userinfo: userinfo,
                        hostport: hostport
                      }, ['userinfo', 'hostport']);
                    }
                  )?

reg_name       =  chars:( unreserved / escaped / "$" / ","
                  / ";" / ":" / "@" / "&" / "=" / "+" )+
                  {return joinEscaped(chars);}
query          =  chars:uric* {return joinEscaped(chars);}
SIP_Version    =  $("SIP"i "/" _version)
_version       =  major:_PDIGITS "." minor:_PDIGITS
                  {
                    return defineSerialize({
                      major: major,
                      minor: minor
                    }, ['major', 'minor'], {separator: '.'});
                  }

_message_headers = message_headers:( message_header )*
                   { return combineHeaders(message_headers); }
message_header  =  message_header:(Accept
                /  Accept_Encoding
                /  Accept_Language
                /  Alert_Info
                /  Allow
                /  Authentication_Info
                /  Authorization
                /  Call_ID
                /  Call_Info
                /  Contact
                /  Content_Disposition
                /  Content_Encoding
                /  Content_Language
                /  Content_Length
                /  Content_Type
                /  CSeq
                /  Date
                /  Error_Info
                /  Expires
                /  From
                /  In_Reply_To
                /  Max_Forwards
                /  MIME_Version
                /  Min_Expires
                /  Organization
                /  Priority
                /  Proxy_Authenticate
                /  Proxy_Authorization
                /  Proxy_Require
                /  Record_Route
                /  Reply_To
// http://tools.ietf.org/html/rfc3261#page-225
                /  Require
                /  Retry_After
                /  Route
                /  Server
                /  Subject
                /  Supported
                /  Timestamp
                /  To
                /  Unsupported
                /  User_Agent
                /  Via
                /  Warning
                /  WWW_Authenticate
                // begin RFC 3262
                // http://tools.ietf.org/html/rfc3262#section-10
                /  RAck
                /  RSeq
                // end RFC 3262
                /  Reason // RFC 3326 // http://tools.ietf.org/html/rfc3326#section-2
                /  Path // RFC 3327 // http://tools.ietf.org/html/rfc3327#section-4
                /  Refer_To // RFC 3515 // http://tools.ietf.org/html/rfc3515#section-2.1
                /  Flow_Timer // RFC 5626 // http://tools.ietf.org/html/rfc5626#appendix-B
                // begin RFC 6665
                // http://tools.ietf.org/html/rfc6665#section-8.4
                /  Allow_Events
                /  Event
                /  Subscription_State
                // end RFC 6665
                /  extension_header) CRLF
                {
                  return message_header;
                }

Method            =  token

Response          =  Status_Line:Status_Line
                     message_headers:_message_headers
                     CRLF
                     message_body:( message_body )?
                     {
                       return defineSerialize({
                         Status_Line: Status_Line,
                         message_headers: message_headers,
                         message_body: message_body
                       }, ['Status_Line', 'message_headers', '\r\n', 'message_body']);
                     }

Status_Line     =  SIP_Version:SIP_Version SP Status_Code:Status_Code SP Reason_Phrase:Reason_Phrase CRLF
                   {
                     return defineSerialize({
                       SIP_Version: SIP_Version,
                       Status_Code: Status_Code,
                       Reason_Phrase: Reason_Phrase
                     }, ['SIP_Version', 'Status_Code', 'Reason_Phrase'], {
                       separator: ' ',
                       suffix: '\r\n'
                     });
                   }

Status_Code     =  _PDIGIT3
Reason_Phrase   =  chars:(reserved / unreserved / escaped
                   / UTF8_NONASCII / UTF8_CONT / SP / HTAB)*
                   {return joinEscaped(chars);}

// http://tools.ietf.org/html/rfc3261#page-227
Accept         =  name:"Accept"i HCOLON
                  value:(
                    first:accept_range
                    rest:(COMMA a:accept_range {return a;})*
                    { return [first].concat(rest); }
                  )?
                  {return {name: "Accept", value: value};}
accept_range   =  media_range:media_range accept_params:(SEMI a:accept_param {return a;})*
                  {
                    return xparamsBuild(media_range, 'media_range', accept_params, 'accept_params');
                  }
//media_range    =  ( "*/*"
//                  / ( m_type SLASH "*" )
//                  / ( m_type SLASH m_subtype )
//                  ) ( SEMI m_parameter )*
media_range    =  media_type
accept_param   =  (
                    name:"q" EQUAL value:qvalue
                    {return {name: name, value: value};}
                  ) / generic_param
qvalue         =  value:$(
                    ( "0" ( "." _0to3DIGIT )? )
                    / ( "1" ( "." "0" )? )
                  )
                  {
                    return parseFloat(value);
                  }
_0to3DIGIT     =  DIGIT? DIGIT? DIGIT?
generic_param  =  name:token value:( EQUAL g:gen_value {return g;} )?
                  {return {name: name, value: value};}
gen_value      =  token / host / quoted_string

Accept_Encoding  =  name:"Accept-Encoding"i HCOLON
                    value:(
                      first:encoding
                      rest:(COMMA e:encoding {return e;})*
                      { return [first].concat(rest); }
                    )?
                    {return {name: "Accept-Encoding", value: value};}
encoding         =  codings:codings
                    accept_params:(SEMI a:accept_param {return a;})*
                    {
                      return xparamsBuild(codings, 'codings', accept_params, 'accept_params');
                    }
codings          =  content_coding / "*"
content_coding   =  token

Accept_Language  =  name:"Accept-Language"i HCOLON
                    value:(
                      first:language
                      rest:(COMMA l:language {return l;})*
                      { return [first].concat(rest); }
                    )?
                    {return {name: "Accept-Language", value: value};}
language         =  language_range:language_range
                    accept_params:(SEMI a:accept_param {return a;})*
                    {
                      return xparamsBuild(language_range, 'language_range', accept_params, 'accept_params');
                    }
language_range   =  $ ( ( _1to8ALPHA ( "-" _1to8ALPHA )* ) / "*" )
_1to8ALPHA       = ALPHA ALPHA? ALPHA? ALPHA? ALPHA? ALPHA? ALPHA? ALPHA?

Alert_Info   =  name:"Alert-Info"i HCOLON
                value:(
                  first:alert_param
                  rest:(COMMA a:alert_param {return a;})*
                  { return [first].concat(rest); }
                )
                {return {name: "Alert-Info", value: value};}
alert_param  =  LAQUOT absoluteURI:absoluteURI RAQUOT
                params:( SEMI g:generic_param {return g;} )*
                {
                  return xparamsBuild(absoluteURI, 'absoluteURI', params);
                }

Allow  =  name:"Allow"i HCOLON
          value:(
            first:Method
            rest:(COMMA m:Method {return m;})*
            { return [first].concat(rest); }
          )?
          {return {name: "Allow", value: value};}

Authorization     =  name:"Authorization"i HCOLON value:credentials
                     {return {name: "Authorization", value: value};}
credentials       =  (
                       "Digest" LWS d:digest_response
                       {
                         return defineSerialize({
                           digest_response: d
                         }, ['Digest ', 'digest_response']);
                       }
                     )
                     / (o:other_response {
                         return defineSerialize({
                           other_response: o
                         }, ['other_response']);
                       })
digest_response   =  first:dig_resp
                     rest:(COMMA d:dig_resp {return d;})*
                     { return combineParams([first].concat(rest), {separator: ', '}); }
dig_resp          =  username / realm / nonce / digest_uri
                      / dresponse / algorithm / cnonce
                      / opaque / message_qop
                      / nonce_count / auth_param
username          =  name:"username" EQUAL value:username_value
                     {return {name: name, value: value};}
username_value    =  quoted_string
digest_uri        =  name:"uri" EQUAL LDQUOT value:digest_uri_value RDQUOT
                     {return {name: name, value: value};}
//digest_uri_value  =  rquest_uri // Equal to request_uri as specified by HTTP/1.1
//digest_uri_value  =  request_uri // Equal to request_uri as specified by HTTP/1.1
digest_uri_value  =  Request_URI // Equal to request_uri as specified by HTTP/1.1
message_qop       =  name:"qop" EQUAL value:qop_value
                     {return {name: name, value: value};}

// http://tools.ietf.org/html/rfc3261#page-228
cnonce            =  name:"cnonce" EQUAL value:cnonce_value
                     {return {name: name, value: value};}
cnonce_value      =  nonce_value
nonce_count       =  name:"nc" EQUAL value:nc_value
                     {return {name: name, value: value};}
nc_value          =  _8LHEX
_8LHEX            =  LHEX LHEX LHEX LHEX LHEX LHEX LHEX LHEX
dresponse         =  name:"response" EQUAL value:request_digest
                     {return {name: name, value: value};}
request_digest    =  LDQUOT _32LHEX RDQUOT
_32LHEX           =  _8LHEX _8LHEX _8LHEX _8LHEX
auth_param        =  name:auth_param_name EQUAL
                     value:( token / quoted_string )
                     {return {name: name, value: value};}
auth_param_name   =  token
other_response    =  auth_scheme:auth_scheme LWS first:auth_param
                     rest:(COMMA a:auth_param {return a;})*
                     {
                       auth_params = [first].concat(rest);
                       return xparamsBuild(auth_scheme, 'auth_scheme', auth_params, 'auth_params', {
                         separator: ', ',
                         prefix: ' '
                       });
                     }
auth_scheme       =  token

Authentication_Info  =  name:"Authentication-Info"i HCOLON
                        value:(
                          first:ainfo
                          rest:(COMMA a:ainfo {return a;})*
                          { return combineParams([first].concat(rest), {separator: ', '}); }
                        )
                        {return {name: "Authentication-Info", value: value};}
ainfo                =  nextnonce / message_qop
                         / response_auth / cnonce
                         / nonce_count
nextnonce            =  name:"nextnonce" EQUAL value:nonce_value
                        {return {name: name, value: value};}
response_auth        =  name:"rspauth" EQUAL value:response_digest
                        {return {name: name, value: value};}
response_digest      =  LDQUOT value:$(LHEX*) RDQUOT {return value;}

Call_ID  =  name:( "Call-ID"i / "i"i ) HCOLON value:callid
            {return {name: "Call-ID", value: value};}
callid   =  $( word ( "@" word )? )

Call_Info   =  name:"Call-Info"i HCOLON
               value:(
                 first:info
                 rest:(COMMA i:info {return i;})*
                 { return [first].concat(rest); }
               )
               {return {name: "Call-Info", value: value};}
info        =  LAQUOT absoluteURI:absoluteURI RAQUOT
               info_params:( SEMI i:info_param {return i;} )*
               {
                 return xparamsBuild(absoluteURI, 'absoluteURI', info_params, 'info_params');
               }
info_param  =  (
                 name:"purpose" EQUAL
                 value:( "icon" / "info" / "card" / token )
                 {return {name: name, value: value};}
               ) / generic_param

Contact        =  name:("Contact"i / "m"i ) HCOLON
                  value:(
                    STAR /
                    (
                      first:contact_param
                      rest:(COMMA c:contact_param {return c;})*
                      { return [first].concat(rest); }
                    )
                  )
                  {return {name: "Contact", value: value};}
contact_param  =  addr:(name_addr / addr_spec)
                  params:(SEMI c:contact_params {return c;})*
                  {
                    return addrparamsBuild(addr, params);
                  }
name_addr      =  display_name:( display_name )?
                  LAQUOT addr_spec:addr_spec RAQUOT
                  {
                    if (display_name) {
                      addr_spec.display_name = display_name;
                    }
                    Object.defineProperty(addr_spec, '_isNameAddr', {value: true});
                    return addr_spec;
                  }
addr_spec      =  SIP_URI / SIPS_URI / absoluteURI
display_name   =  quoted_string / $( (token LWS)* )

contact_params     =  c_p_q / c_p_expires
                      // begin RFC 5626
                      // http://tools.ietf.org/html/rfc5626#appendix-B
                      / c_p_reg
                      / c_p_instance
                      // end RFC 5626
                      / contact_extension
c_p_q              =  name:"q" EQUAL value:qvalue
                      {return {name: name, value: value};}
c_p_expires        =  name:"expires" EQUAL value:delta_seconds
                      {return {name: name, value: value};}
// begin RFC 5626
// http://tools.ietf.org/html/rfc5626#appendix-B
c_p_reg            =  name:"reg-id" EQUAL value:_PDIGITS // 1 to (2^31 - 1)
                      {return {name: name, value: value};}
c_p_instance       =  name:"+sip.instance" EQUAL
                      DQUOTE "<" value:instance_val ">" DQUOTE
                      {return {name: name, value: value};}

// defined in RFC 3261
instance_val       =  chars:uric+ {return joinEscaped(chars);}
// end RFC 5626

contact_extension  =  generic_param
delta_seconds      =  _PDIGITS

Content_Disposition   =  name:"Content-Disposition"i HCOLON
                         value:(
                           disp_type:disp_type
                           disp_params:( SEMI d:disp_param {return d;} )*
                           {
                             return xparamsBuild(disp_type, 'disp_type', disp_params, 'disp_params');
                           }
                         )
                         {return {name: "Content-Disposition", value: value};}
disp_type             =  token
// http://tools.ietf.org/html/rfc3261#page-229
disp_param            =  handling_param / generic_param
handling_param        =  name:"handling" EQUAL
                         value:( "optional" / "required"
                         / other_handling )
                         {return {name: name, value: value};}
other_handling        =  token

Content_Encoding  =  name:( "Content-Encoding"i / "e"i ) HCOLON
                     value:(
                       first:content_coding
                       rest:(COMMA c:content_coding {return c;})*
                       { return [first].concat(rest); }
                     )
                     {return {name: "Content-Encoding", value: value};}

Content_Language  =  name:"Content-Language"i HCOLON
                     value:(
                       first:language_tag
                       rest:(COMMA l:language_tag {return c;})*
                       { return [first].concat(rest); }
                     )
                     {return {name: "Content-Language", value: value};}
language_tag      =  primary_tag:primary_tag
                     subtags:( "-" s:subtag {return s;})*
                     {
                       return defineSerialize({
                         primary_tag: primary_tag,
                         subtags: subtags
                       }, ['primary_tag', 'subtags']);
                     }
primary_tag       =  _1to8ALPHA
subtag            =  _1to8ALPHA

Content_Length   =  name:( "Content-Length"i / "l"i ) HCOLON value:_PDIGITS
                    { return {name: "Content-Length", value: value}; }
Content_Type     =  name:( "Content-Type"i / "c"i ) HCOLON value:media_type
                    {return {name: "Content-Type", value: value};}
media_type       =  m_type:m_type SLASH m_subtype:m_subtype
                    m_parameters:(SEMI p:m_parameter {return p;})*
                    {
                      m_parameters = combineParams(m_parameters);
                      return defineSerialize({
                        m_type: m_type,
                        m_subtype: m_subtype,
                        m_parameters: m_parameters
                      }, ['m_type', '/', 'm_subtype', 'm_parameters']);
                    }
m_type           =  token
m_subtype        =  token
m_parameter      =  name:m_attribute EQUAL value:m_value
                    {return {name: name, value: value};}
m_attribute      =  token
m_value          =  token / quoted_string

CSeq  =  name:"CSeq"i HCOLON
         value:(
           sequenceNumber:_PDIGITS LWS requestMethod:Method
           {
             return defineSerialize({
               sequenceNumber: sequenceNumber,
               requestMethod: requestMethod
             }, ['sequenceNumber', 'requestMethod'], {separator: ' '});
           }
         )
         {return {name: "CSeq", value: value};}

Date          =  name:"Date"i HCOLON value:SIP_date
                 {return {name: "Date", value: value};}
SIP_date      =  rfc1123_date
rfc1123_date  =  wkday:wkday "," SP date1:date1 SP time:time SP "GMT"
                 {
                   return defineSerialize({
                     wkday: wkday,
                     date1: date1,
                     time: time
                   }, ['wkday', ', ', 'date1', ' ', 'time', ' GMT']);
                 }
date1         =  day:_PDIGIT2 SP month:month SP year:_PDIGIT4
                 // day month year (e.g., 02 Jun 1982)
                 {
                   return defineSerialize({
                     day: day,
                     month: month,
                     year: year
                   }, ['day', 'month', 'year'], {separator: ' '});
                 }
time          =  hours:_PDIGIT2 ":" minutes:_PDIGIT2 ":" seconds:_PDIGIT2
                 // 00:00:00 _ 23:59:59
                 {
                   return defineSerialize({
                     hours: hours,
                     minutes: minutes,
                     seconds: seconds
                   }, ['hours', 'minutes', 'seconds'], {separator: ':'});
                 }
wkday         =  "Mon" / "Tue" / "Wed"
                 / "Thu" / "Fri" / "Sat" / "Sun"
month         =  "Jan" / "Feb" / "Mar" / "Apr"
                 / "May" / "Jun" / "Jul" / "Aug"
                 / "Sep" / "Oct" / "Nov" / "Dec"

Error_Info  =  name:"Error-Info"i HCOLON
               value:(
                 first:error_uri
                 rest:(COMMA e:error_uri {return e;})*
                 { return [first].concat(rest); }
               )
               {return {name: "Error-Info", value: value};}

// http://tools.ietf.org/html/rfc3261#page-230
error_uri   =  LAQUOT absoluteURI:absoluteURI RAQUOT
               params:( SEMI g:generic_param {return g;} )*
               {
                 return xparamsBuild(absoluteURI, 'absoluteURI', params);
               }

Expires     =  name:"Expires"i HCOLON value:delta_seconds
               {return {name: "Expires", value: value};}
From        =  name:( "From"i / "f"i ) HCOLON value:from_spec
               {return {name: "From", value: value};}
from_spec   =  addr:(name_addr / addr_spec)
               params:(SEMI f:from_param {return f;})*
               {
                 return addrparamsBuild(addr, params);
               }
from_param  =  tag_param / generic_param
tag_param   =  name:"tag" EQUAL value:token
               {return {name: name, value: value};}

In_Reply_To  =  name:"In-Reply-To"i HCOLON
                value:(
                  first:callid
                  rest:(COMMA c:callid {return c;})*
                  { return [first].concat(rest); }
                )
                {return {name: "In-Reply-To", value: value};}

Max_Forwards  =  name:"Max-Forwards"i HCOLON value:_PDIGITS
                 {return {name: "Max-Forwards", value: value};}

MIME_Version  =  name:"MIME-Version"i HCOLON
                 value: _version
                 {return {name: "MIME-Version", value: value};}

Min_Expires  =  name:"Min-Expires"i HCOLON value:delta_seconds
                {return {name: "Min-Expires", value: value};}

Organization  =  name:"Organization"i HCOLON value:(TEXT_UTF8_TRIM)?
                 {return {name: "Organization", value: value};}

Priority        =  name:"Priority"i HCOLON value:priority_value
                   {return {name: "Priority", value: value};}
priority_value  =  "emergency" / "urgent" / "normal"
                   / "non-urgent" / other_priority
other_priority  =  token

Proxy_Authenticate  =  name:"Proxy-Authenticate"i HCOLON value:challenge
                       {return {name: "Proxy-Authenticate", value: value};}
challenge           =  (
                         "Digest" LWS
                         first:digest_cln
                         rest:(COMMA d:digest_cln {return d;})*
                         { return {digest_clns: [first].concat(rest)}; }
                       )
                       / (o:other_challenge {return {other_challenge: o};})
other_challenge     =  auth_scheme:auth_scheme LWS first:auth_param
                       rest:(COMMA a:auth_param {return a;})*
                       {
                         auth_params = [first].concat(rest);
                         return xparamsBuild(auth_scheme, 'auth_scheme', auth_params, 'auth_params', ', ');
                       }
digest_cln          =  realm / domain / nonce
                        / opaque / stale / algorithm
                        / qop_options / auth_param
realm               =  name:"realm" EQUAL value:realm_value
                       {return {name: name, value: value};}
realm_value         =  quoted_string
domain              =  name:"domain" EQUAL LDQUOT
                       value:(
                         first:URI rest:( SP+ u:URI {return u;} )*
                         { return [first].concat(rest); }
                       )
                       RDQUOT
                       {return {name: name, value: value};}
URI                 =  absoluteURI / abs_path
nonce               =  name:"nonce" EQUAL value:nonce_value
                       {return {name: name, value: value};}
nonce_value         =  quoted_string
opaque              =  name:"opaque" EQUAL value:quoted_string
                       {return {name: name, value: value};}
stale               =  name:"stale" EQUAL value:( "true" / "false" )
                       {return {name: name, value: value};}
algorithm           =  name:"algorithm" EQUAL value:( "MD5" / "MD5-sess"
                       / token )
                       {return {name: name, value: value};}
qop_options         =  name:"qop" EQUAL LDQUOT
                       value:(
                         first:qop_value rest:( "," v:qop_value {return v;} )*
                         { return [first].concat(rest); }
                       )
                       RDQUOT
                       {return {name: name, value: value};}
qop_value           =  "auth" / "auth-int" / token

Proxy_Authorization  =  name:"Proxy-Authorization"i HCOLON value:credentials
                        {return {name: "Proxy-Authorization", value: value};}

// http://tools.ietf.org/html/rfc3261#page-231
Proxy_Require  =  name:"Proxy-Require"i HCOLON
                  value:(
                    first:option_tag
                    rest:(COMMA o:option_tag {return o;})*
                    { return [first].concat(rest); }
                  )
                  {return {name: "Proxy-Require", value: value};}
option_tag     =  token

Record_Route  =  name:"Record-Route"i HCOLON
                  value:(
                    first:rec_route
                    rest:(COMMA r:rec_route {return r;})*
                    { return [first].concat(rest); }
                  )
                  {return {name: "Record-Route", value: value};}
rec_route     =  addr:name_addr
                 params:( SEMI r:rr_param {return r;} )*
                 {
                   return addrparamsBuild(addr, params);
                 }
rr_param      =  generic_param

Reply_To      =  name:"Reply-To"i HCOLON value:rplyto_spec
                 {return {name: "Reply-To", value: value};}
rplyto_spec   =  addr:( name_addr / addr_spec )
                 params:( SEMI r:rplyto_param {return r;} )*
                 {
                   return addrparamsBuild(addr, params);
                 }
rplyto_param  =  generic_param
Require       =  name:"Require"i HCOLON
                 value:(
                   first:option_tag
                   rest:(COMMA o:option_tag {return o;})*
                   { return [first].concat(rest); }
                 )
                 {return {name: "Require", value: value};}

Retry_After  =  name:"Retry-After"i HCOLON
                value:(
                  delta_seconds:delta_seconds
                  comment:( comment )?
                  retry_params:( SEMI r:retry_param {return r;} )*
                  {
                    retry_params = combineParams(retry_params);
                    return defineSerialize({
                      delta_seconds: delta_seconds,
                      comment: comment,
                      retry_params: retry_params
                    }, ['delta_seconds', 'comment', 'retry_params']);
                  }
                )
                {return {name: "Retry-After", value: value};}

retry_param  =  (
                  name:"duration" EQUAL value:delta_seconds
                  {return {name: name, value: value};}
                )
                / generic_param

Route        =  name:"Route"i HCOLON
                value:(
                  first:route_param
                  rest:(COMMA r:route_param {return r;})*
                  { return [first].concat(rest); }
                )
                {return {name: "Route", value: value};}
route_param  =  addr:name_addr params:( SEMI r:rr_param {return r;} )*
                {
                  return addrparamsBuild(addr, params);
                }

Server           =  name:"Server"i HCOLON
                    value:(
                      first:server_val
                      rest:(LWS server_val)*
                      { return [first].concat(rest); }
                    )
                    {return {name: "Server", value: value};}
server_val       =  product / comment
product          =  product_name:token product_version:(SLASH p:product_version {return p;})?
                    {
                      return defineSerialize({
                        product_name: product_name,
                        product_version: product_version
                      }, ['product_name', 'product_version'], {separator: '/'});
                    }
product_version  =  token

Subject  =  name:( "Subject"i / "s"i ) HCOLON value:$(TEXT_UTF8_TRIM)?
            {return {name: "Subject", value: value};}

Supported  =  name:( "Supported"i / "k"i ) HCOLON
              value:(
                first:option_tag
                rest:(COMMA o:option_tag {return o;})*
                { return [first].concat(rest); }
              )?
              {return {name: "Supported", value: value};}

Timestamp  =  name:"Timestamp"i HCOLON
              value:$(
                (DIGIT)+
                ( "." (DIGIT)* )? ( LWS delay )?
              )
              {return {name: "Timestamp", value: value};}
delay      =  (DIGIT)* ( "." (DIGIT)* )?

To        =  name:( "To"i / "t"i ) HCOLON
             value:(
               addr:( name_addr / addr_spec )
               params:( SEMI t:to_param {return t;} )*
               {
                 return addrparamsBuild(addr, params);
               }
             )
             {return {name: "To", value: value};}
to_param  =  tag_param / generic_param

Unsupported  =  name:"Unsupported"i HCOLON
                value:(
                  first:option_tag
                  rest:(COMMA o:option_tag {return o;})*
                  { return [first].concat(rest); }
                )
                {return {name: "Unsupported", value: value};}
User_Agent  =  name:"User-Agent"i HCOLON
                value:(
                  first:server_val
                  rest:(LWS s:server_val {return s;})*
                  { return [first].concat(rest); }
                )
                {return {name: "User-Agent", value: value};}

// http://tools.ietf.org/html/rfc3261#page-232
Via               =  name:( "Via"i / "v"i ) HCOLON
                     value:(
                       first:via_parm
                       rest:(COMMA v:via_parm {return v;})*
                       { return [first].concat(rest); }
                     )
                     {return {name: "Via", value: value};}
via_parm          =  sent_protocol:sent_protocol LWS sent_by:sent_by
                     params:( SEMI v:via_params {return v;} )*
                     {
                       params = combineParams(params);
                       return defineSerialize({
                         sent_protocol: sent_protocol,
                         sent_by: sent_by,
                         params: params
                       }, ['sent_protocol', ' ', 'sent_by', 'params']);
                     }
via_params        =  via_ttl / via_maddr
                     / via_received / via_branch
                     / via_extension
via_ttl           =  name:"ttl" EQUAL value:ttl
                     {return {name: name, value: value};}
via_maddr         =  name:"maddr" EQUAL value:host
                     {return {name: name, value: value};}
via_received      =  name:"received" EQUAL value:(IPv4address / IPv6address)
                     {return {name: name, value: value};}
via_branch        =  name:"branch" EQUAL value:token
                     {return {name: name, value: value};}
via_extension     =  generic_param
sent_protocol     =  protocol_name:protocol_name SLASH protocol_version:protocol_version
                     SLASH transport:transport
                     {
                       return defineSerialize({
                         protocol_name: protocol_name,
                         protocol_version: protocol_version,
                         transport: transport
                       }, ['protocol_name', 'protocol_version', 'transport'], {separator: '/'});
                     }
protocol_name     =  "SIP" / token
protocol_version  =  token

// begin RFC 7118 (augments transport & transport_param)
// http://tools.ietf.org/html/rfc7118
transport         =  "UDP" / "TCP" / "TLS" / "SCTP"
                    / "WSS" / "WS"
                    / other_transport
// end RFC 7118

sent_by           =  host:host port:( COLON p:port {return p;} )?
                     {
                       return hostportBuild(host, port);
                     }
// ttl               =  1*3DIGIT // 0 to 255
ttl             = "25" [\x30-\x35]          // 250-255
                / "2" [\x30-\x34] DIGIT     // 200-249
                / "1" DIGIT DIGIT           // 100-199
                / [\x31-\x39] DIGIT         // 10-99
                / DIGIT                     // 0-9

Warning        =  name:"Warning"i HCOLON
                  value:(
                    first:warning_value
                    rest:(COMMA w:warning_value {return w;})*
                    { return [first].concat(rest); }
                  )
                  {return {name: "Warning", value: value};}
warning_value  =  warn_code:warn_code SP warn_agent:warn_agent SP warn_text:warn_text
                  {
                    return defineSerialize({
                      warn_code: warn_code,
                      warn_agent: warn_agent,
                      warn_text: warn_text
                    }, ['warn_code', 'warn_agent', 'warn_text'], {separator: ' '});
                  }
warn_code      =  _PDIGIT3
warn_agent     =  hostport / pseudonym
                  //  the name or pseudonym of the server adding
                  //  the Warning header, for use in debugging
warn_text      =  quoted_string
pseudonym      =  token

WWW_Authenticate  =  name:"WWW-Authenticate"i HCOLON value:challenge
                     {return {name: "WWW-Authenticate", value: value};}

// begin RFC 3262
// http://tools.ietf.org/html/rfc3262#section-10
RAck          =  name:"RAck"i HCOLON
                 value:(
                   response_num:response_num LWS
                   CSeq_num:CSeq_num LWS
                   Method:Method
                   {
                     return defineSerialize({
                       response_num: response_num,
                       CSeq_num: CSeq_num,
                       Method: Method
                     }, ['response_num', 'CSeq_num', 'Method'], {separator: ' '});
                   }
                 )
                 {return {name: "RAck", value: value};}
response_num  =  _PDIGITS
CSeq_num      =  _PDIGITS
RSeq          =  name:"RSeq"i HCOLON value:response_num
                 {return {name: "RSeq", value: value};}
// end RFC 3262

// begin RFC 3326
// http://tools.ietf.org/html/rfc3326#section-2
Reason            =  name:"Reason"i HCOLON
                     value:(
                       first:reason_value
                       rest:(COMMA r:reason_value {return r;})*
                       { return [first].concat(rest); }
                     )
                     {return {name: "Reason", value: value};}
reason_value      =  protocol:protocol
                     params:(SEMI r:reason_params {return r;})*
                     {
                       return xparamsBuild(protocol, 'protocol', params);
                     }
protocol          =  "SIP" / "Q.850" / token
reason_params     =  protocol_cause / reason_text
                     / reason_extension
protocol_cause    =  name:"cause" EQUAL value:cause
                     {return {name: name, value: value};}
cause             =  _PDIGITS
reason_text       =  name:"text" EQUAL value:quoted_string
                     {return {name: name, value: value};}
reason_extension  =  generic_param
// end RFC 3326

// begin RFC 3327
// http://tools.ietf.org/html/rfc3327#section-4
Path       = name:"Path"i HCOLON
             value:(
               first:path_value
               rest:( COMMA p:path_value {return p;} )*
               { return [first].concat(rest); }
             )
             {return {name: "Path", value: value};}
path_value = addr:name_addr
             params:( SEMI p:rr_param {return p;} )*
             {
               return addrparamsBuild(addr, params);
             }
// end RFC 3327

// begin RFC 3515
// http://tools.ietf.org/html/rfc3515#section-2.1
Refer_To = name:("Refer-To"i / "r"i) HCOLON
           value:(
             addr:( name_addr / addr_spec )
             params:(SEMI p:generic_param {return p;})*
             {
               return addrparamsBuild(addr, params);
             }
           )
           {return {name: "Refer-To", value: value};}
// end RFC 3515

// begin RFC 5626
// http://tools.ietf.org/html/rfc5626#appendix-B
Flow_Timer     = name:"Flow-Timer"i HCOLON value:_PDIGITS
                 {return {name: "Flow-Timer", value: value};}
// end RFC 5626

// begin RFC 6665
// http://tools.ietf.org/html/rfc6665#section-8.4
Event             =  name:( "Event"i / "o"i ) HCOLON
                     value:(
                       type:event_type
                       params:( SEMI p:event_param {return p;} )*
                       {
                         return xparamsBuild(type, 'type', params);
                       }
                     )
                     {return {name: name, value: value};}
event_type        =  event_package:event_package
                     templates:( "." t:event_template {return t;} )*
                     {
                       return defineSerialize({
                         event_package: event_package,
                         templates: templates
                       }, ['event_package', 'templates']);
                     }
event_package     =  token_nodot
event_template    =  token_nodot
token_nodot       =  $( ( alphanum / "-"  / "!" / "%" / "*"
                         / "_" / "+" / "`" / "'" / "~" )+ )

// The use of the "id" parameter is deprecated; it is included
// for backwards-compatibility purposes only.
//event_param       =  generic_param / ( "id" EQUAL token )
event_param       =  generic_param // no need to parse "id" separately


Allow_Events      =  name:( "Allow-Events"i / "u"i ) HCOLON
                     value:(
                       first:event_type
                       rest:(COMMA t:event_type {return t;})*
                       { return [first].concat(rest); }
                     )
                     {return {name: "Allow-Events", value: value};}

Subscription_State   = name:"Subscription-State"i HCOLON
                       value:(
                         substate_value:substate_value
                         params:( SEMI p:subexp_params {return p;} )*
                         {
                           return xparamsBuild(substate_value, 'substate_value', params);
                         }
                       )
                       {return {name: "Subscription-State", value: value};}
substate_value       = token
subexp_params        =   (name:"reason" EQUAL value:event_reason_value {return {name: name, value: value};} )
                       / (name:"expires" EQUAL value:delta_seconds {return {name: name, value: value};} )
                       / (name:"retry-after" EQUAL value:delta_seconds {return {name: name, value: value};} )
                       / generic_param
event_reason_value   = token
// end RFC 6665

extension_header  =  name:header_name HCOLON value:header_value
                     {return {name: name, value: value};}
header_name       =  token
header_value      =  $( (TEXT_UTF8char / UTF8_CONT / LWS)* )
message_body  =  $( OCTET* )
