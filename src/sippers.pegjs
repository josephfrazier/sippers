{
  function mapList (append, list) {
    return list.reduce(
      function combine (map, item) {
        var name = item.name;
        var value = item.value;
        if (append && Array.isArray(value)) {
          value = (map[name] || []).concat(value);
        }
        map[name] = value;
        return map;
      },
      {}
    );
  }

  // See RFC 3261 Section 7.3
  var combineHeaders = mapList.bind(null, true);
  // non-RFC, just convenient
  var combineParams = mapList.bind(null, false);
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
               {return decodeURIComponent(text());}

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
comment  =  LPAREN value:$((ctext / quoted_pair / comment)*) RPAREN {return value;}
ctext    =  [\x21-\x27] / [\x2A-\x5B] / [\x5D-\x7E] / UTF8_NONASCII
            / LWS


quoted_string  =  SWS DQUOTE value:$((qdtext / quoted_pair )*) DQUOTE {return value;}
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
                      return {
                        scheme: 'sip'
                        ,userinfo: userinfo
                        ,hostport: hostport
                        ,uri_parameters: uri_parameters
                        ,headers: headers
                      };
                    }

SIPS_URI          =  "sips:" userinfo:( userinfo )? hostport:hostport
                     uri_parameters:uri_parameters headers:( headers )?
                     {
                      return {
                        scheme: 'sips'
                        ,userinfo: userinfo
                        ,hostport: hostport
                        ,uri_parameters: uri_parameters
                        ,headers: headers
                      };
                    }

//TODO telephone_subscriber
//userinfo         =  ( user / telephone_subscriber ) ( ":" password )? "@"
userinfo         =  user:( user ) password:( ":" p:password {return p;} )? "@"
                    {
                      return {
                        user: user,
                        password: password
                      };
                    }
user             =  chars:( unreserved / escaped / user_unreserved )+
                    {return chars.join('');}

user_unreserved  =  "&" / "=" / "+" / "$" / "," / ";" / "?" / "/"
password         =  chars:( unreserved / escaped /
                    "&" / "=" / "+" / "$" / "," )*
                    {return chars.join('');}

hostport         =  host:host port:( ":" p:port {return p;} )?
                    {
                      return {
                        host: host,
                        port: port
                      };
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
port           =  $ DIGIT+

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
                     { return { name: 'transport', value: value }; }
// end RFC 7118

other_transport   =  token

user_param        =  "user=" value:( "phone" / "ip" / other_user)
                     { return { name: 'user', value: value }; }
other_user        =  token

method_param      =  "method=" value:Method
                     { return { name: 'method', value: value }; }
ttl_param         =  "ttl=" value:ttl
                     { return { name: 'ttl', value: value }; }
maddr_param       =  "maddr=" value:host
                     { return { name: 'maddr', value: value }; }
lr_param          =  "lr" {return {name: 'lr', value: null }; }
other_param       =  name:pname value:( "=" v:pvalue {return v;} )?
                     {return {name: name, value: value};}
pname             =  _paramchars
pvalue            =  _paramchars
_paramchars       =  chars:paramchar+ {return chars.join('');}
paramchar         =  param_unreserved / unreserved / escaped
param_unreserved  =  "[" / "]" / "/" / ":" / "&" / "+" / "$"

headers         =  "?" first:header rest:( "&" h:header {return h;} )*
                   { return combineParams([first].concat(rest)); }
header          =  name:hname "=" value:hvalue
                   {return {name: name, value: value};}
hname           =  chars:_hchar+ {return chars.join('');}
hvalue          =  chars:_hchar* {return chars.join('');}
_hchar          =  hnv_unreserved / unreserved / escaped
hnv_unreserved  =  "[" / "]" / "/" / "?" / ":" / "+" / "$"

SIP_message    =  Request / Response

Request        =  Request_Line:Request_Line
                  message_headers:_message_headers
                  CRLF
                  message_body:( message_body )?
                  {
                    return {
                      Request_Line: Request_Line,
                      message_headers: message_headers,
                      message_body: message_body
                    };
                  }

Request_Line   =  Method:Method SP Request_URI:Request_URI SP SIP_Version:SIP_Version CRLF
                  {
                    return {
                      Method: Method,
                      Request_URI: Request_URI,
                      SIP_Version: SIP_Version
                    };
                  }

Request_URI    =  SIP_URI / SIPS_URI / absoluteURI
absoluteURI    =  scheme:scheme ":" part:( hier_part / opaque_part )
                  {
                    return {
                      scheme: scheme,
                      part: part
                    };
                  }

hier_part      =  path:( net_path / abs_path ) query:( "?" q:query {return q;} )?
                  {
                    return {
                      path: path,
                      query: query
                    };
                  }

net_path       =  "//" authority:authority abs_path:( abs_path )?
                  {
                    return {
                      authority: authority,
                      abs_path: abs_path
                    };
                  }
abs_path       =  "/" path_segments:path_segments {return path_segments;}

// http://tools.ietf.org/html/rfc3261#page-224
opaque_part    =  ns:uric_no_slash chars:uric*
                  {return ns + chars.join('');}
uric           =  reserved / unreserved / escaped
uric_no_slash  =  unreserved / escaped / ";" / "?" / ":" / "@"
                  / "&" / "=" / "+" / "$" / ","
path_segments  =  first:segment rest:( "/" s:segment {return s;} )*
                  { return [first].concat(rest); }
segment        =  value:_pchars
                  params:( ";" p:param {return p;} )*
                  {
                    params = combineParams(params);
                    return {
                      value: value,
                      params: params
                    };
                  }
param          =  _pchars
_pchars        =  chars:pchar* {return chars.join('');}
pchar          =  unreserved / escaped /
                  ":" / "@" / "&" / "=" / "+" / "$" / ","
scheme         =  $( ALPHA ( ALPHA / DIGIT / "+" / "-" / "." )* )
authority      =  srvr / reg_name

srvr           =  (
                    userinfo:userinfo?
                    hostport: hostport
                    {
                      return {
                        userinfo: userinfo,
                        hostport: hostport
                      };
                    }
                  )?

reg_name       =  chars:( unreserved / escaped / "$" / ","
                  / ";" / ":" / "@" / "&" / "=" / "+" )+
                  {return chars.join();}
query          =  chars:uric* {return chars.join('');}
SIP_Version    =  "SIP"i "/" major:$(DIGIT+) "." minor:$(DIGIT+)
                  {
                    return {
                      major: parseInt(major, 10),
                      minor: parseInt(minor, 10)
                    };
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

INVITEm           =  "INVITE" // INVITE in caps
ACKm              =  "ACK" // ACK in caps
OPTIONSm          =  "OPTIONS" // OPTIONS in caps
BYEm              =  "BYE" // BYE in caps
CANCELm           =  "CANCEL" // CANCEL in caps
REGISTERm         =  "REGISTER" // REGISTER in caps
PRACKm            =  "PRACK" // PRACK in caps, RFC 3262 // http://tools.ietf.org/html/rfc3262#section-10
MESSAGEm          =  "MESSAGE" // MESSAGE in caps // RFC 3428 // http://tools.ietf.org/html/rfc3428#section-9
REFERm            =  "REFER" // REFER in caps // RFC 3515 // http://tools.ietf.org/html/rfc3515#section-2.1
SUBSCRIBEm        =  "SUBSCRIBE" // SUBSCRIBE in caps // RFC 6665 // http://tools.ietf.org/html/rfc6665#section-8.4
NOTIFYm           =  "NOTIFY" // NOTIFY in caps // RFC 6665 // http://tools.ietf.org/html/rfc6665#section-8.4
Method            =  INVITEm / ACKm / OPTIONSm / BYEm
                     / CANCELm / REGISTERm
                     / PRACKm // RFC 3262 // http://tools.ietf.org/html/rfc3262#section-10
                     / MESSAGEm // RFC 3428 // http://tools.ietf.org/html/rfc3428#section-9
                     / REFERm // RFC 3515 // http://tools.ietf.org/html/rfc3515#section-2.1
                     / SUBSCRIBEm / NOTIFYm // RFC 6665 // http://tools.ietf.org/html/rfc6665#section-3.2
                     / extension_method
extension_method  =  token

Response          =  Status_Line:Status_Line
                     message_headers:_message_headers
                     CRLF
                     message_body:( message_body )?
                     {
                       return {
                         Status_Line: Status_Line,
                         message_headers: message_headers,
                         message_body: message_body
                       };
                     }

Status_Line     =  SIP_Version:SIP_Version SP Status_Code:Status_Code SP Reason_Phrase:Reason_Phrase CRLF
                   {
                     return {
                       SIP_Version: SIP_Version,
                       Status_Code: Status_Code,
                       Reason_Phrase: Reason_Phrase
                     };
                   }

Status_Code     =  text:$(
                   Informational
               /   Redirection
               /   Success
               /   Client_Error
               /   Server_Error
               /   Global_Failure
               /   extension_code
                   )
                   {
                     return parseInt(text, 10);
                   }
extension_code  =  DIGIT DIGIT DIGIT
Reason_Phrase   =  chars:(reserved / unreserved / escaped
                   / UTF8_NONASCII / UTF8_CONT / SP / HTAB)*
                   {return chars.join('');}

Informational  =  "100"  //  Trying
              /   "180"  //  Ringing
              /   "181"  //  Call Is Being Forwarded
              /   "182"  //  Queued
              /   "183"  //  Session Progress

// http://tools.ietf.org/html/rfc3261#page-226
Success  =  "200"  //  OK
        /   "202"  //  Accepted // RFC 6665 // http://tools.ietf.org/html/rfc6665#section-7.4

Redirection  =  "300"  //  Multiple Choices
            /   "301"  //  Moved Permanently
            /   "302"  //  Moved Temporarily
            /   "305"  //  Use Proxy
            /   "380"  //  Alternative Service

Client_Error  =  "400"  //  Bad Request
             /   "401"  //  Unauthorized
             /   "402"  //  Payment Required
             /   "403"  //  Forbidden
             /   "404"  //  Not Found
             /   "405"  //  Method Not Allowed
             /   "406"  //  Not Acceptable
             /   "407"  //  Proxy Authentication Required
             /   "408"  //  Request Timeout
             /   "410"  //  Gone
             /   "413"  //  Request Entity Too Large
             /   "414"  //  Request_URI Too Large
             /   "415"  //  Unsupported Media Type
             /   "416"  //  Unsupported URI Scheme
             /   "420"  //  Bad Extension
             /   "421"  //  Extension Required
             /   "423"  //  Interval Too Brief
             /   "480"  //  Temporarily not available
             /   "481"  //  Call Leg/Transaction Does Not Exist
             /   "482"  //  Loop Detected
             /   "483"  //  Too Many Hops
             /   "484"  //  Address Incomplete
             /   "485"  //  Ambiguous
             /   "486"  //  Busy Here
             /   "487"  //  Request Terminated
             /   "488"  //  Not Acceptable Here
             /   "489"  //  Bad Event // RFC 6665 // http://tools.ietf.org/html/rfc6665#section-7.4
             /   "491"  //  Request Pending
             /   "493"  //  Undecipherable

Server_Error  =  "500"  //  Internal Server Error
             /   "501"  //  Not Implemented
             /   "502"  //  Bad Gateway
             /   "503"  //  Service Unavailable
             /   "504"  //  Server Time_out
             /   "505"  //  SIP Version not supported
             /   "513"  //  Message Too Large

// http://tools.ietf.org/html/rfc3261#page-227
Global_Failure  =  "600"  //  Busy Everywhere
               /   "603"  //  Decline
               /   "604"  //  Does not exist anywhere
               /   "606"  //  Not Acceptable

Accept         =  name:"Accept"i HCOLON
                  value:(
                    first:accept_range
                    rest:(COMMA a:accept_range {return a;})*
                    { return [first].concat(rest); }
                  )?
                  {return {name: "Accept", value: value};}
accept_range   =  media_range:media_range accept_params:(SEMI a:accept_param {return a;})*
                  {
                    accept_params = combineParams(accept_params);
                    return {
                      media_range: media_range,
                      accept_params: accept_params
                    };
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
                      accept_params = combineParams(accept_params);
                      return {
                        codings: codings,
                        accept_params: accept_params
                      };
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
                      accept_params = combineParams(accept_params);
                      return {
                        language_range: language_range,
                        accept_params: accept_params
                      };
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
                generic_params:( SEMI g:generic_param {return g;} )*
                {
                  generic_params = combineParams(generic_params);
                  return {
                    absoluteURI: absoluteURI,
                    generic_params: generic_params
                  };
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
                         return { digest_response: d };
                       }
                     )
                     / (o:other_response {return {other_response: o};})
digest_response   =  first:dig_resp
                     rest:(COMMA d:dig_resp {return d;})*
                     { return combineParams([first].concat(rest)); }
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
                       return {
                         auth_scheme: auth_scheme,
                         auth_params: combineParams([first].concat(rest))
                       };
                     }
auth_scheme       =  token

Authentication_Info  =  name:"Authentication-Info"i HCOLON
                        value:(
                          first:ainfo
                          rest:(COMMA a:ainfo {return a;})*
                          { return combineParams([first].concat(rest)); }
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
                 info_params = combineParams(info_params);
                 return {
                   absoluteURI: absoluteURI,
                   info_params: info_params
                 };
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
                    params = combineParams(params);
                    return {
                      addr: addr,
                      params: params
                    };
                  }
name_addr      =  display_name:( display_name )?
                  LAQUOT addr_spec:addr_spec RAQUOT
                  {
                    addr_spec.display_name = display_name;
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
c_p_reg            =  name:"reg-id" EQUAL value:$(DIGIT+) // 1 to (2^31 - 1)
                      {return {name: name, value: parseInt(value, 10)};}
c_p_instance       =  name:"+sip.instance" EQUAL
                      DQUOTE "<" value:instance_val ">" DQUOTE
                      {return {name: name, value: value};}

// defined in RFC 3261
instance_val       =  chars:uric+ {return chars.join('');}
// end RFC 5626

contact_extension  =  generic_param
delta_seconds      =  DIGIT+ { return parseInt(text(), 10); }

Content_Disposition   =  name:"Content-Disposition"i HCOLON
                         value:(
                           disp_type:disp_type
                           disp_params:( SEMI d:disp_param {return d;} )*
                           {
                             disp_params = combineParams(disp_params);
                             return {
                               disp_type: disp_type,
                               disp_params: disp_params
                             };
                           }
                         )
                         {return {name: "Content-Disposition", value: value};}
disp_type             =  "render" / "session" / "icon" / "alert"
                         / disp_extension_token
// http://tools.ietf.org/html/rfc3261#page-229
disp_param            =  handling_param / generic_param
handling_param        =  name:"handling" EQUAL
                         value:( "optional" / "required"
                         / other_handling )
                         {return {name: name, value: value};}
other_handling        =  token
disp_extension_token  =  token

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
                       return {
                         primary_tag: primary_tag,
                         subtags: subtags
                       };
                     }
primary_tag       =  _1to8ALPHA
subtag            =  _1to8ALPHA

Content_Length   =  name:( "Content-Length"i / "l"i ) HCOLON value:$(DIGIT+)
                    { return { name: "Content-Length" , value: parseInt(value, 10) }; }
Content_Type     =  name:( "Content-Type"i / "c"i ) HCOLON value:media_type
                    {return {name: "Content-Type", value: value};}
media_type       =  m_type:m_type SLASH m_subtype:m_subtype
                    m_parameters:(SEMI p:m_parameter {return p;})*
                    {
                      m_parameters = combineParams(m_parameters);
                      return {
                        m_type: m_type,
                        m_subtype: m_subtype,
                        m_parameters: m_parameters
                      };
                    }
m_type           =  discrete_type / composite_type
discrete_type    =  "text" / "image" / "audio" / "video"
                    / "application" / extension_token
composite_type   =  "message" / "multipart" / extension_token
extension_token  =  ietf_token / x_token
ietf_token       =  token
x_token          =  "x-" token
m_subtype        =  extension_token / iana_token
iana_token       =  token
m_parameter      =  name:m_attribute EQUAL value:m_value
                    {return {name: name, value: value};}
m_attribute      =  token
m_value          =  token / quoted_string

CSeq  =  name:"CSeq"i HCOLON
         value:(
           sequenceNumber:$(DIGIT+) LWS requestMethod:Method
           {
             return {
               sequenceNumber: parseInt(sequenceNumber, 10),
               requestMethod: requestMethod
             };
           }
         )
         {return {name: "CSeq", value: value};}

Date          =  name:"Date"i HCOLON value:SIP_date
                 {return {name: "Date", value: value};}
SIP_date      =  rfc1123_date
rfc1123_date  =  wkday:wkday "," SP date1:date1 SP time:time SP "GMT"
                 {
                   return {
                     wkday: wkday,
                     date1: date1,
                     time: time
                   };
                 }
_2DIGIT       =  DIGIT DIGIT
_4DIGIT       =  _2DIGIT _2DIGIT
date1         =  day:$(_2DIGIT) SP month:month SP year:$(_4DIGIT)
                 // day month year (e.g., 02 Jun 1982)
                 {
                   return {
                     day: parseInt(day, 10),
                     month: month,
                     year: parseInt(year, 10)
                   };
                 }
time          =  hours:$(_2DIGIT) ":" minutes:$(_2DIGIT) ":" seconds:$(_2DIGIT)
                 // 00:00:00 _ 23:59:59
                 {
                   return {
                     hours: parseInt(hours, 10),
                     minutes: parseInt(minutes, 10),
                     seconds: parseInt(seconds, 10)
                   };
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
               generic_params:( SEMI g:generic_param {return g;} )*
               {
                 generic_params = combineParams(generic_params);
                 return {
                   absoluteURI: absoluteURI,
                   generic_params: generic_params
                 };
               }

Expires     =  name:"Expires"i HCOLON value:delta_seconds
               {return {name: "Expires", value: value};}
From        =  name:( "From"i / "f"i ) HCOLON value:from_spec
               {return {name: "From", value: value};}
from_spec   =  addr:(name_addr / addr_spec)
               params:(SEMI f:from_param {return f;})*
               {
                 params = combineParams(params);
                 return {
                   addr: addr,
                   params: params
                 };
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

Max_Forwards  =  name:"Max-Forwards"i HCOLON value:$(DIGIT+)
                 {return {name: "Max-Forwards", value: parseInt(value, 10)};}

MIME_Version  =  name:"MIME-Version"i HCOLON
                 value:(
                   major:$(DIGIT+) "."
                   minor:$(DIGIT+)
                   {
                     return {
                       major: parseInt(major, 10),
                       minor: parseInt(minor, 10)
                     };
                   }
                 )
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
                         return {
                           auth_scheme: auth_scheme,
                           auth_params: combineParams([first].concat(rest))
                         };
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
                   params = combineParams(params);
                   return {
                     addr: addr,
                     params: params
                   };
                 }
rr_param      =  generic_param

Reply_To      =  name:"Reply-To"i HCOLON value:rplyto_spec
                 {return {name: "Reply-To", value: value};}
rplyto_spec   =  addr:( name_addr / addr_spec )
                 params:( SEMI r:rplyto_param {return r;} )*
                 {
                   return {
                     addr: addr,
                     params: combineParams(params)
                   };
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
                    return {
                      delta_seconds: delta_seconds,
                      comment: comment,
                      retry_params: retry_params
                    };
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
                  params = combineParams(params);
                  return {
                    addr: addr,
                    params: params
                  };
                }

Server           =  name:"Server"i HCOLON
                    value:(
                      first:server_val
                      rest:(LWS server_val)*
                      { return [first].concat(rest); }
                    )
                    {return {name: "Server", value: value};}
server_val       =  product / (c:comment {return {comment: c};})
product          =  token:token product_version:(SLASH p:product_version {return p;})?
                    {
                      return {
                        token: token,
                        product_version: product_version
                      };
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
                 params = combineParams(params);
                 return {
                   addr: addr,
                   params: params
                 };
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
                       return {
                         sent_protocol: sent_protocol,
                         sent_by: sent_by,
                         params: params
                       };
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
                       return {
                         protocol_name: protocol_name,
                         protocol_version: protocol_version,
                         transport: transport
                       };
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
                       return {
                         host: host,
                         port: port
                       };
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
                    return {
                      warn_code: warn_code,
                      warn_agent: warn_agent,
                      warn_text: warn_text
                    };
                  }
warn_code      =  DIGIT DIGIT DIGIT {return parseInt(text(), 10);}
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
                     return {
                       response_num: response_num,
                       CSeq_num: CSeq_num,
                       Method: Method
                     };
                   }
                 )
                 {return {name: "RAck", value: value};}
response_num  =  DIGIT+ {return parseInt(text(), 10);}
CSeq_num      =  DIGIT+ {return parseInt(text(), 10);}
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
                       params = combineParams(params);
                       return {
                         protocol: protocol,
                         params: params
                       };
                     }
protocol          =  "SIP" / "Q.850" / token
reason_params     =  protocol_cause / reason_text
                     / reason_extension
protocol_cause    =  name:"cause" EQUAL value:cause
                     {return {name: name, value: value};}
cause             =  DIGIT+ {return parseInt(text(), 10);}
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
               params = combineParams(params);
               return {
                 addr: addr,
                 params: params
               };
             }
// end RFC 3327

// begin RFC 3515
// http://tools.ietf.org/html/rfc3515#section-2.1
Refer_To = name:("Refer-To"i / "r"i) HCOLON
           value:(
             addr:( name_addr / addr_spec )
             params:(SEMI p:generic_param {return p;})*
             {
               return {
                 addr: addr,
                 params: params
               };
             }
           )
           {return {name: "Refer-To", value: value};}
// end RFC 3515

// begin RFC 5626
// http://tools.ietf.org/html/rfc5626#appendix-B
Flow_Timer     = name:"Flow-Timer"i HCOLON value:$(DIGIT+)
                 {return {name: "Flow-Timer", value: parseInt(value, 10)};}
// end RFC 5626

// begin RFC 6665
// http://tools.ietf.org/html/rfc6665#section-8.4
Event             =  name:( "Event"i / "o"i ) HCOLON
                     value:(
                       type:event_type
                       params:( SEMI p:event_param {return p;} )*
                       {
                         params = combineParams(params);
                         return {
                           type: type,
                           params: params
                         };
                       }
                     )
                     {return {name: name, value: value};}
event_type        =  event_package:event_package
                     templates:( "." t:event_template {return t;} )*
                     {
                       return {
                         event_package: event_package,
                         templates: templates
                       };
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
                           params = combineParams(params);
                           return {
                             substate_value: substate_value,
                             params: params
                           };
                         }
                       )
                       {return {name: "Subscription-State", value: value};}
substate_value       = "active" / "pending" / "terminated"
                       / extension_substate
extension_substate   = token
subexp_params        =   (name:"reason" EQUAL value:event_reason_value {return {name: name, value: value};} )
                       / (name:"expires" EQUAL value:delta_seconds {return {name: name, value: value};} )
                       / (name:"retry-after" EQUAL value:delta_seconds {return {name: name, value: value};} )
                       / generic_param
event_reason_value   =   "deactivated"
                       / "probation"
                       / "rejected"
                       / "timeout"
                       / "giveup"
                       / "noresource"
                       / "invariant"
                       / event_reason_extension
event_reason_extension = token
// end RFC 6665

extension_header  =  name:header_name HCOLON value:header_value
                     {return {name: name, value: value};}
header_name       =  token
header_value      =  $( (TEXT_UTF8char / UTF8_CONT / LWS)* )
message_body  =  $( OCTET* )
