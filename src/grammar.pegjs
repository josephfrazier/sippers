{
  var helpers = require('./helpers');
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
_PDIGITS       =  DIGIT+ {return helpers.padInt(text());}
_PDIGIT2       =  DIGIT DIGIT {return helpers.padInt(text(), 2);}
_PDIGIT3       =  DIGIT DIGIT DIGIT {return helpers.padInt(text(), 3);}
_PDIGIT4       =  DIGIT DIGIT DIGIT DIGIT {return helpers.padInt(text(), 4);}
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
                 return helpers.defineDelimited(decoded, text());
               }

/* RFC3261 25: A recipient MAY replace any linear white space with a single SP
 * before interpreting the field value or forwarding the message downstream
 */
// Don't fold over lines. That should be done before input reaches parser.
// This helps with parsing empty headers.
// TODO undo this change, find a better way to flexibily parse headers?
//LWS  =  (WSP* CRLF)? WSP+ {return ' ';} // linear whitespace
LWS  =  WSP+ {return ' ';} // linear whitespace
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
              return helpers.defineDelimited(value, '(' + value + ')');
            }
ctext    =  [\x21-\x27] / [\x2A-\x5B] / [\x5D-\x7E] / UTF8_NONASCII
            / LWS


quoted_string  =  SWS DQUOTE value:$((qdtext / quoted_pair )*) DQUOTE
                  {
                    return helpers.defineDelimited(value, '"' + value + '"');
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

_SIP_URI          = scheme:$("sip" "s"?) ":" userinfo:( userinfo )? hostport:hostport
                    parameters:uri_parameters headers:( headers )?
                    {
                      return helpers.sipuriBuild(scheme, userinfo, hostport, parameters, headers);
                    }

_SIP_URI_noparams = scheme:$("sip" "s"?) ":" userinfo:( userinfo )? hostport:hostport
                    headers:( headers )?
                    {
                      return helpers.sipuriBuild(scheme, userinfo, hostport, helpers.combineParams([]), headers);
                    }

SIP_URI           =  _SIP_URI
SIPS_URI          =  _SIP_URI

//TODO telephone_subscriber
//userinfo         =  ( user / telephone_subscriber ) ( ":" password )? "@"
userinfo         =  user:( user ) password:( ":" p:password {return p;} )? "@"
                    {
                      return helpers.serializeable({
                        user: user,
                        password: password
                      }, ['user', 'password'], {
                        separator: ':',
                        suffix: '@'
                      });
                    }
user             =  chars:( unreserved / escaped / user_unreserved )+
                    {return helpers.joinEscaped(chars);}

user_unreserved  =  "&" / "=" / "+" / "$" / "," / ";" / "?" / "/"
password         =  chars:( unreserved / escaped /
                    "&" / "=" / "+" / "$" / "," )*
                    {return helpers.joinEscaped(chars);}

hostport         =  host:host port:( ":" p:port {return p;} )?
                    {
                      return helpers.hostportBuild(host, port);
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
                     { return helpers.combineParams(parameters); }
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
_paramchars       =  chars:paramchar+ {return helpers.joinEscaped(chars);}
paramchar         =  param_unreserved / unreserved / escaped
param_unreserved  =  "[" / "]" / "/" / ":" / "&" / "+" / "$"

headers         =  "?" first:header rest:( "&" h:header {return h;} )*
                   {
                     return helpers.combineParams(helpers.list(first, rest, '&'), {
                       separator: '&',
                       prefix: '?'
                     });
                   }
header          =  name:hname "=" value:hvalue
                   {return {name: name, value: value};}
hname           =  chars:_hchar+ {return helpers.joinEscaped(chars);}
hvalue          =  chars:_hchar* {return helpers.joinEscaped(chars);}
_hchar          =  hnv_unreserved / unreserved / escaped
hnv_unreserved  =  "[" / "]" / "/" / "?" / ":" / "+" / "$"

SIP_message    =  Request / Response

Request        =  Request:Request_Line
                  headers:_message_headers
                  CRLF
                  body:( message_body )?
                  {
                    return helpers.serializeable({
                      Request: Request,
                      headers: headers,
                      body: body
                    }, ['Request', 'headers', '\r\n', 'body']);
                  }

Request_Line   =  Method:Method SP URI:Request_URI SP Version:SIP_Version CRLF
                  {
                    return helpers.serializeable({
                      Method: Method,
                      URI: URI,
                      Version: Version
                    }, ['Method', 'URI', 'Version'], {
                      separator: ' ',
                      suffix: '\r\n'
                    });
                  }

Request_URI    =  SIP_URI / SIPS_URI / absoluteURI
absoluteURI    =  scheme:scheme ":" part:( hier_part / opaque_part )
                  {
                    return helpers.serializeable({
                      scheme: scheme,
                      part: part
                    }, ['scheme', 'part'], {separator: ':'});
                  }
// TODO
_absoluteURI_noparams = absoluteURI

hier_part      =  path:( net_path / abs_path ) query:( "?" q:query {return q;} )?
                  {
                    return helpers.serializeable({
                      path: path,
                      query: query
                    }, ['path', 'query'], {separator: '?'});
                  }

net_path       =  "//" authority:authority abs_path:( abs_path )?
                  {
                    return helpers.serializeable({
                      authority: authority,
                      abs_path: abs_path
                    }, ['//', 'authority', 'abs_path']);
                  }
abs_path       =  "/" path_segments:path_segments {return path_segments;}

// http://tools.ietf.org/html/rfc3261#page-224
opaque_part    =  ns:uric_no_slash chars:uric*
                  {return helpers.joinEscaped([ns].concat(chars));}
uric           =  reserved / unreserved / escaped
uric_no_slash  =  unreserved / escaped / ";" / "?" / ":" / "@"
                  / "&" / "=" / "+" / "$" / ","
path_segments  =  first:segment rest:( "/" s:segment {return s;} )*
                  { return helpers.list(first, rest, '/'); }
segment        =  value:_pchars
                  parameters:( ";" p:param {return p;} )*
                  {
                    return helpers.xparamsBuild(value, 'value', parameters);
                  }
param          =  _pchars
_pchars        =  chars:pchar* {return helpers.joinEscaped(chars);}
pchar          =  unreserved / escaped /
                  ":" / "@" / "&" / "=" / "+" / "$" / ","
scheme         =  $( ALPHA ( ALPHA / DIGIT / "+" / "-" / "." )* )
authority      =  srvr / reg_name

srvr           =  (
                    userinfo:userinfo?
                    hostport: hostport
                    {
                      return helpers.serializeable({
                        userinfo: userinfo,
                        hostport: hostport
                      }, ['userinfo', 'hostport']);
                    }
                  )?

reg_name       =  chars:( unreserved / escaped / "$" / ","
                  / ";" / ":" / "@" / "&" / "=" / "+" )+
                  {return helpers.joinEscaped(chars);}
query          =  chars:uric* {return helpers.joinEscaped(chars);}
SIP_Version    =  $("SIP"i "/" _version)
_version       =  major:_PDIGITS "." minor:_PDIGITS
                  {
                    return helpers.serializeable({
                      major: major,
                      minor: minor
                    }, ['major', 'minor'], {separator: '.'});
                  }

_message_headers = message_headers:( message_header )*
                   { return message_headers; }
message_header  =  message_header:(
                   (h:Accept CRLF {return h;})
                /  (h:Accept_Encoding CRLF {return h;})
                /  (h:Accept_Language CRLF {return h;})
                /  (h:Alert_Info CRLF {return h;})
                /  (h:Allow CRLF {return h;})
                /  (h:Authentication_Info CRLF {return h;})
                /  (h:Authorization CRLF {return h;})
                /  (h:Call_ID CRLF {return h;})
                /  (h:Call_Info CRLF {return h;})
                /  (h:Contact CRLF {return h;})
                /  (h:Content_Disposition CRLF {return h;})
                /  (h:Content_Encoding CRLF {return h;})
                /  (h:Content_Language CRLF {return h;})
                /  (h:Content_Length CRLF {return h;})
                /  (h:Content_Type CRLF {return h;})
                /  (h:CSeq CRLF {return h;})
                /  (h:Date CRLF {return h;})
                /  (h:Error_Info CRLF {return h;})
                /  (h:Expires CRLF {return h;})
                /  (h:From CRLF {return h;})
                /  (h:In_Reply_To CRLF {return h;})
                /  (h:Max_Forwards CRLF {return h;})
                /  (h:MIME_Version CRLF {return h;})
                /  (h:Min_Expires CRLF {return h;})
                /  (h:Organization CRLF {return h;})
                /  (h:Priority CRLF {return h;})
                /  (h:Proxy_Authenticate CRLF {return h;})
                /  (h:Proxy_Authorization CRLF {return h;})
                /  (h:Proxy_Require CRLF {return h;})
                /  (h:Record_Route CRLF {return h;})
                /  (h:Reply_To CRLF {return h;})
// http://tools.ietf.org/html/rfc3261#page-225
                /  (h:Require CRLF {return h;})
                /  (h:Retry_After CRLF {return h;})
                /  (h:Route CRLF {return h;})
                /  (h:Server CRLF {return h;})
                /  (h:Subject CRLF {return h;})
                /  (h:Supported CRLF {return h;})
                /  (h:Timestamp CRLF {return h;})
                /  (h:To CRLF {return h;})
                /  (h:Unsupported CRLF {return h;})
                /  (h:User_Agent CRLF {return h;})
                /  (h:Via CRLF {return h;})
                /  (h:Warning CRLF {return h;})
                /  (h:WWW_Authenticate CRLF {return h;})
                // begin RFC 3262
                // http://tools.ietf.org/html/rfc3262#section-10
                /  (h:RAck CRLF {return h;})
                /  (h:RSeq CRLF {return h;})
                // end RFC 3262
                // RFC 3326 // http://tools.ietf.org/html/rfc3326#section-2
                /  (h:Reason CRLF {return h;})
                // RFC 3327 // http://tools.ietf.org/html/rfc3327#section-4
                /  (h:Path CRLF {return h;})
                // RFC 3515 // http://tools.ietf.org/html/rfc3515#section-2.1
                /  (h:Refer_To CRLF {return h;})
                // RFC 5626 // http://tools.ietf.org/html/rfc5626#appendix-B
                /  (h:Flow_Timer CRLF {return h;})
                // begin RFC 6665
                // http://tools.ietf.org/html/rfc6665#section-8.4
                /  (h:Allow_Events CRLF {return h;})
                /  (h:Event CRLF {return h;})
                /  (h:Subscription_State CRLF {return h;})
                // end RFC 6665
                /  (h:extension_header CRLF {return h;})
                )
                {
                  return helpers.header(message_header.name, message_header.value);
                }

Method            =  token

Response          =  Status:Status_Line
                     headers:_message_headers
                     CRLF
                     body:( message_body )?
                     {
                       return helpers.serializeable({
                         Status: Status,
                         headers: headers,
                         body: body
                       }, ['Status', 'headers', '\r\n', 'body']);
                     }

Status_Line     =  Version:SIP_Version SP Code:Status_Code SP Reason:Reason_Phrase CRLF
                   {
                     return helpers.serializeable({
                       Version: Version,
                       Code: Code,
                       Reason: Reason
                     }, ['Version', 'Code', 'Reason'], {
                       separator: ' ',
                       suffix: '\r\n'
                     });
                   }

Status_Code     =  _PDIGIT3
Reason_Phrase   =  chars:(reserved / unreserved / escaped
                   / UTF8_NONASCII / UTF8_CONT / SP / HTAB)*
                   {return helpers.joinEscaped(chars);}

// http://tools.ietf.org/html/rfc3261#page-227
// RFC 3261 20.1: An empty Accept header field means that no formats are acceptable.
Accept         =  name:"Accept"i HCOLON
                  value:(
                    first:accept_range
                    rest:(COMMA a:accept_range {return a;})*
                    { return helpers.list(first, rest); }
                  )?
                  {return {name: "Accept", value: value || []};}
accept_range   =  range:media_range parameters:(SEMI a:accept_param {return a;})*
                  {
                    return helpers.xparamsBuild(range, 'range', parameters, 'parameters');
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

/* RFC 3261 20.2
    An empty Accept-Encoding header field is permissible.  It is equivalent to
    Accept-Encoding: identity, that is, only the identity encoding, meaning no
    encoding, is permissible.
*/
Accept_Encoding  =  name:"Accept-Encoding"i HCOLON
                    value:(
                      first:encoding
                      rest:(COMMA e:encoding {return e;})*
                      { return helpers.list(first, rest); }
                    )?
                    {return {name: "Accept-Encoding", value: value || [parse('identity', {startRule: 'encoding'})]};}
encoding         =  codings:codings
                    parameters:(SEMI a:accept_param {return a;})*
                    {
                      return helpers.xparamsBuild(codings, 'codings', parameters, 'parameters');
                    }
codings          =  content_coding / "*"
content_coding   =  token

Accept_Language  =  name:"Accept-Language"i HCOLON
                    value:(
                      first:language
                      rest:(COMMA l:language {return l;})*
                      { return helpers.list(first, rest); }
                    )?
                    {return {name: "Accept-Language", value: value || []};}
language         =  range:language_range
                    parameters:(SEMI a:accept_param {return a;})*
                    {
                      return helpers.xparamsBuild(range, 'range', parameters, 'parameters');
                    }
language_range   =  $ ( ( _1to8ALPHA ( "-" _1to8ALPHA )* ) / "*" )
_1to8ALPHA       = ALPHA ALPHA? ALPHA? ALPHA? ALPHA? ALPHA? ALPHA? ALPHA?

Alert_Info   =  name:"Alert-Info"i HCOLON
                value:(
                  first:alert_param
                  rest:(COMMA a:alert_param {return a;})*
                  { return helpers.list(first, rest); }
                )
                {return {name: "Alert-Info", value: value};}
alert_param  =  LAQUOT absoluteURI:absoluteURI RAQUOT
                parameters:( SEMI g:generic_param {return g;} )*
                {
                  return helpers.xparamsBuild(absoluteURI, 'absoluteURI', parameters);
                }

Allow  =  name:"Allow"i HCOLON
          value:(
            first:Method
            rest:(COMMA m:Method {return m;})*
            { return helpers.list(first, rest); }
          )?
          {return {name: "Allow", value: value || []};}

Authorization     =  name:"Authorization"i HCOLON value:credentials
                     {return {name: "Authorization", value: value};}
credentials       =  (
                       "Digest" LWS digest:digest_response
                       {
                         return helpers.serializeable({
                           digest: digest
                         }, ['Digest ', 'digest']);
                       }
                     )
                     / (other:other_response {
                         return helpers.serializeable({
                           other: other
                         }, ['other']);
                       })
digest_response   =  first:dig_resp
                     rest:(COMMA d:dig_resp {return d;})*
                     { return helpers.combineParams(helpers.list(first, rest), {separator: ', '}); }
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
other_response    =  scheme:auth_scheme LWS first:auth_param
                     rest:(COMMA a:auth_param {return a;})*
                     {
                       parameters = helpers.list(first, rest);
                       return helpers.xparamsBuild(scheme, 'scheme', parameters, 'parameters', {
                         separator: ', ',
                         prefix: ' '
                       });
                     }
auth_scheme       =  token

Authentication_Info  =  name:"Authentication-Info"i HCOLON
                        value:(
                          first:ainfo
                          rest:(COMMA a:ainfo {return a;})*
                          { return helpers.combineParams(helpers.list(first, rest), {separator: ', '}); }
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
                 { return helpers.list(first, rest); }
               )
               {return {name: "Call-Info", value: value};}
info        =  LAQUOT absoluteURI:absoluteURI RAQUOT
               parameters:( SEMI i:info_param {return i;} )*
               {
                 return helpers.xparamsBuild(absoluteURI, 'absoluteURI', parameters, 'parameters');
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
                      { return helpers.list(first, rest); }
                    )
                  )
                  {return {name: "Contact", value: value};}
contact_param  =  addr:(name_addr / _addr_spec_noparams)
                  parameters:(SEMI c:contact_params {return c;})*
                  {
                    return helpers.addrparamsBuild(addr, parameters);
                  }
name_addr      =  name:( display_name )?
                  LAQUOT addr_spec:addr_spec RAQUOT
                  {
                    if (name) {
                      addr_spec.name = name;
                    }
                    Object.defineProperty(addr_spec, '_isNameAddr', {value: true});
                    return addr_spec;
                  }
addr_spec      =  SIP_URI / SIPS_URI / absoluteURI
_addr_spec_noparams = _SIP_URI_noparams / _absoluteURI_noparams
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
c_p_expires        =  name:"expires" EQUAL
                      value:(delta_seconds / (gen_value {return helpers.padInt(3600);}))
                      {return {name: name, value: value};}
// begin RFC 5626
// http://tools.ietf.org/html/rfc5626#appendix-B
c_p_reg            =  name:"reg-id" EQUAL value:_PDIGITS // 1 to (2^31 - 1)
                      {return {name: name, value: value};}
c_p_instance       =  name:"+sip.instance" EQUAL
                      DQUOTE "<" value:instance_val ">" DQUOTE
                      {return {name: name, value: value};}

// defined in RFC 3261
instance_val       =  chars:uric+ {return helpers.joinEscaped(chars);}
// end RFC 5626

contact_extension  =  generic_param
delta_seconds      =  _PDIGITS

Content_Disposition   =  name:"Content-Disposition"i HCOLON
                         value:(
                           disp_type:disp_type
                           parameters:( SEMI d:disp_param {return d;} )*
                           {
                             return helpers.xparamsBuild(disp_type, 'disp_type', parameters, 'parameters');
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
                       { return helpers.list(first, rest); }
                     )
                     {return {name: "Content-Encoding", value: value};}

Content_Language  =  name:"Content-Language"i HCOLON
                     value:(
                       first:language_tag
                       rest:(COMMA l:language_tag {return c;})*
                       { return helpers.list(first, rest); }
                     )
                     {return {name: "Content-Language", value: value};}
language_tag      =  primary_tag:primary_tag
                     subtags:( "-" s:subtag {return s;})*
                     {
                       return helpers.serializeable({
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
media_type       =  type:m_type SLASH subtype:m_subtype
                    parameters:(SEMI p:m_parameter {return p;})*
                    {
                      parameters = helpers.combineParams(parameters);
                      return helpers.serializeable({
                        type: type,
                        subtype: subtype,
                        parameters: parameters
                      }, ['type', '/', 'subtype', 'parameters']);
                    }
m_type           =  token
m_subtype        =  token
m_parameter      =  name:m_attribute EQUAL value:m_value
                    {return {name: name, value: value};}
m_attribute      =  token
m_value          =  token / quoted_string

CSeq  =  name:"CSeq"i HCOLON
         value:(
           number:_PDIGITS LWS method:Method
           {
             return helpers.serializeable({
               number: number,
               method: method
             }, ['number', 'method'], {separator: ' '});
           }
         )
         {return {name: "CSeq", value: value};}

Date          =  name:"Date"i HCOLON value:SIP_date
                 {return {name: "Date", value: value};}
SIP_date      =  rfc1123_date
rfc1123_date  =  wkday:wkday "," SP date1:date1 SP time:time SP "GMT"
                 {
                   return helpers.serializeable({
                     wkday: wkday,
                     date1: date1,
                     time: time
                   }, ['wkday', ', ', 'date1', ' ', 'time', ' GMT']);
                 }
date1         =  day:_PDIGIT2 SP month:month SP year:_PDIGIT4
                 // day month year (e.g., 02 Jun 1982)
                 {
                   return helpers.serializeable({
                     day: day,
                     month: month,
                     year: year
                   }, ['day', 'month', 'year'], {separator: ' '});
                 }
time          =  hours:_PDIGIT2 ":" minutes:_PDIGIT2 ":" seconds:_PDIGIT2
                 // 00:00:00 _ 23:59:59
                 {
                   return helpers.serializeable({
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
                 { return helpers.list(first, rest); }
               )
               {return {name: "Error-Info", value: value};}

// http://tools.ietf.org/html/rfc3261#page-230
error_uri   =  LAQUOT absoluteURI:absoluteURI RAQUOT
               parameters:( SEMI g:generic_param {return g;} )*
               {
                 return helpers.xparamsBuild(absoluteURI, 'absoluteURI', parameters);
               }

Expires     =  name:"Expires"i HCOLON
               value:(delta_seconds / (header_value {return helpers.padInt(3600);}))
               {return {name: "Expires", value: value};}
From        =  name:( "From"i / "f"i ) HCOLON value:from_spec
               {return {name: "From", value: value};}
from_spec   =  addr:(name_addr / _addr_spec_noparams)
               parameters:(SEMI f:from_param {return f;})*
               {
                 return helpers.addrparamsBuild(addr, parameters);
               }
from_param  =  tag_param / generic_param
tag_param   =  name:"tag" EQUAL value:token
               {return {name: name, value: value};}

In_Reply_To  =  name:"In-Reply-To"i HCOLON
                value:(
                  first:callid
                  rest:(COMMA c:callid {return c;})*
                  { return helpers.list(first, rest); }
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
                         { return {digest: helpers.list(first, rest)}; }
                       )
                       / (other:other_challenge {return {other: other};})
other_challenge     =  scheme:auth_scheme LWS first:auth_param
                       rest:(COMMA a:auth_param {return a;})*
                       {
                         parameters = helpers.list(first, rest);
                         return helpers.xparamsBuild(scheme, 'scheme', parameters, 'parameters', ', ');
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
                         { return helpers.list(first, rest, ' '); }
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
                         { return helpers.list(first, rest, ','); }
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
                    { return helpers.list(first, rest); }
                  )
                  {return {name: "Proxy-Require", value: value};}
option_tag     =  token

Record_Route  =  name:"Record-Route"i HCOLON
                  value:(
                    first:rec_route
                    rest:(COMMA r:rec_route {return r;})*
                    { return helpers.list(first, rest); }
                  )
                  {return {name: "Record-Route", value: value};}
rec_route     =  addr:name_addr
                 parameters:( SEMI r:rr_param {return r;} )*
                 {
                   return helpers.addrparamsBuild(addr, parameters);
                 }
rr_param      =  generic_param

Reply_To      =  name:"Reply-To"i HCOLON value:rplyto_spec
                 {return {name: "Reply-To", value: value};}
rplyto_spec   =  addr:( name_addr / addr_spec )
                 parameters:( SEMI r:rplyto_param {return r;} )*
                 {
                   return helpers.addrparamsBuild(addr, parameters);
                 }
rplyto_param  =  generic_param
Require       =  name:"Require"i HCOLON
                 value:(
                   first:option_tag
                   rest:(COMMA o:option_tag {return o;})*
                   { return helpers.list(first, rest); }
                 )
                 {return {name: "Require", value: value};}

Retry_After  =  name:"Retry-After"i HCOLON
                value:(
                  delta_seconds:delta_seconds
                  comment:( comment )?
                  parameters:( SEMI r:retry_param {return r;} )*
                  {
                    parameters = helpers.combineParams(parameters);
                    return helpers.serializeable({
                      delta_seconds: delta_seconds,
                      comment: comment,
                      parameters: parameters
                    }, ['delta_seconds', 'comment', 'parameters']);
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
                  { return helpers.list(first, rest); }
                )
                {return {name: "Route", value: value};}
route_param  =  addr:name_addr parameters:( SEMI r:rr_param {return r;} )*
                {
                  return helpers.addrparamsBuild(addr, parameters);
                }

Server           =  name:"Server"i HCOLON
                    value:(
                      first:server_val
                      rest:(LWS server_val)*
                      { return helpers.list(first, rest, ' '); }
                    )
                    {return {name: "Server", value: value};}
server_val       =  product / comment
product          =  name:token version:(SLASH p:product_version {return p;})?
                    {
                      return helpers.serializeable({
                        name: name,
                        version: version
                      }, ['name', 'version'], {separator: '/'});
                    }
product_version  =  token

Subject  =  name:( "Subject"i / "s"i ) HCOLON value:$(TEXT_UTF8_TRIM)?
            {return {name: "Subject", value: value};}

// RFC 3261 20.37 If empty, it means that no extensions are supported.
Supported  =  name:( "Supported"i / "k"i ) HCOLON
              value:(
                first:option_tag
                rest:(COMMA o:option_tag {return o;})*
                { return helpers.list(first, rest); }
              )?
              {return {name: "Supported", value: value || []};}

Timestamp  =  name:"Timestamp"i HCOLON
              value:$(
                (DIGIT)+
                ( "." (DIGIT)* )? ( LWS delay )?
              )
              {return {name: "Timestamp", value: value};}
delay      =  (DIGIT)* ( "." (DIGIT)* )?

To        =  name:( "To"i / "t"i ) HCOLON
             value:(
               addr:( name_addr / _addr_spec_noparams )
               parameters:( SEMI t:to_param {return t;} )*
               {
                 return helpers.addrparamsBuild(addr, parameters);
               }
             )
             {return {name: "To", value: value};}
to_param  =  tag_param / generic_param

Unsupported  =  name:"Unsupported"i HCOLON
                value:(
                  first:option_tag
                  rest:(COMMA o:option_tag {return o;})*
                  { return helpers.list(first, rest); }
                )
                {return {name: "Unsupported", value: value};}
User_Agent  =  name:"User-Agent"i HCOLON
                value:(
                  first:server_val
                  rest:(LWS s:server_val {return s;})*
                  { return helpers.list(first, rest, ' '); }
                )
                {return {name: "User-Agent", value: value};}

// http://tools.ietf.org/html/rfc3261#page-232
Via               =  name:( "Via"i / "v"i ) HCOLON
                     value:(
                       first:via_parm
                       rest:(COMMA v:via_parm {return v;})*
                       { return helpers.list(first, rest); }
                     )
                     {return {name: "Via", value: value};}
via_parm          =  protocol:sent_protocol LWS by:sent_by
                     parameters:( SEMI v:via_params {return v;} )*
                     {
                       parameters = helpers.combineParams(parameters);
                       return helpers.serializeable({
                         protocol: protocol,
                         by: by,
                         parameters: parameters
                       }, ['protocol', ' ', 'by', 'parameters']);
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
sent_protocol     =  name:protocol_name SLASH version:protocol_version
                     SLASH transport:transport
                     {
                       return helpers.serializeable({
                         name: name,
                         version: version,
                         transport: transport
                       }, ['name', 'version', 'transport'], {separator: '/'});
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
                       return helpers.hostportBuild(host, port);
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
                    { return helpers.list(first, rest); }
                  )
                  {return {name: "Warning", value: value};}
warning_value  =  warn_code:warn_code SP warn_agent:warn_agent SP warn_text:warn_text
                  {
                    return helpers.serializeable({
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
                     return helpers.serializeable({
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
                       { return helpers.list(first, rest); }
                     )
                     {return {name: "Reason", value: value};}
reason_value      =  protocol:protocol
                     parameters:(SEMI r:reason_params {return r;})*
                     {
                       return helpers.xparamsBuild(protocol, 'protocol', parameters);
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
               { return helpers.list(first, rest); }
             )
             {return {name: "Path", value: value};}
path_value = addr:name_addr
             parameters:( SEMI p:rr_param {return p;} )*
             {
               return helpers.addrparamsBuild(addr, parameters);
             }
// end RFC 3327

// begin RFC 3515
// http://tools.ietf.org/html/rfc3515#section-2.1
Refer_To = name:("Refer-To"i / "r"i) HCOLON
           value:(
             addr:( name_addr / addr_spec )
             parameters:(SEMI p:generic_param {return p;})*
             {
               return helpers.addrparamsBuild(addr, parameters);
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
                       parameters:( SEMI p:event_param {return p;} )*
                       {
                         return helpers.xparamsBuild(type, 'type', parameters);
                       }
                     )
                     {return {name: name, value: value};}
event_type        =  event_package:event_package
                     templates:( "." t:event_template {return t;} )*
                     {
                       return helpers.serializeable({
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
                       { return helpers.list(first, rest); }
                     )
                     {return {name: "Allow-Events", value: value};}

Subscription_State   = name:"Subscription-State"i HCOLON
                       value:(
                         substate_value:substate_value
                         parameters:( SEMI p:subexp_params {return p;} )*
                         {
                           return helpers.xparamsBuild(substate_value, 'substate_value', parameters);
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
                     {return {name: name, value: value, $isExtension: true};}
header_name       =  token
header_value      =  $( (TEXT_UTF8char / UTF8_CONT / LWS)* )
message_body  =  $( OCTET* )
