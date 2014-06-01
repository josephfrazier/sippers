function mapList (isHeaders, list, serializeOptions) {
  function combine (map, item) {
    var name = item.name;
    var value = item.value;
    if (isHeaders) {
      var prevValue = map[name];
      var prevArray = Array.isArray(prevValue);
      if (prevArray) {
        value = prevValue.concat(value);
      }
      else if (prevValue) {
        throw new Error(name);
      }
    }
    map[name] = value;
    return map;
  }

  var combined = list.reduce(combine, {});

  function serializeList (isHeaders, options) {
    options = options || {};
    var separator = options.separator;
    var prefix = options.prefix;

    var keySerialize = function (name) {
      // cast to array
      var values = [].concat(this[name]);
      values = values.map(function(i){return serialize(i);});
      if (isHeaders) {
        var headerSep = name === 'User-Agent' ? ' ' : ', ';
        var joined = values.join(headerSep);
        return name + ': ' + joined + '\r\n';
      }
      else {
        return (separator || ';') + name + (values[0] ? '=' + values[0] : '');
      }
    }.bind(this);

    var serialized = Object.keys(this).map(keySerialize).join('');
    if (separator) {
      serialized = serialized.slice(separator.length);
    }
    if (prefix) {
      serialized = prefix + serialized;
    }
    return serialized;
  }

  return Object.defineProperty(combined, 'serialize', {
    value: serializeList.bind(combined, isHeaders, serializeOptions)
  });
}

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
  return transform(prefix + serialized + suffix);
}

function list (first, rest, options) {
  options = options || ', ';
  if (options.constructor === String) {
    options = {separator: options};
  }
  return serializeable([first].concat(rest), ['this'], options);
}

function header (name, value) {
  return serializeable({
    name: name,
    value: value
  }, ['name', ': ', 'value']);
}

function sipuriBuild (scheme, userinfo, hostport, params, headers) {
  return serializeable({
      scheme: scheme
    , userinfo: userinfo
    , hostport: hostport
    , params: params
    , headers: headers
  }, ['scheme', ':', 'userinfo', 'hostport', 'params', 'headers'], {
    transform: function (addrSpecString) {
      if (this.display_name || this._isNameAddr) {
        addrSpecString = serialize(this.display_name) + '<' + addrSpecString + '>';
      }
      return addrSpecString;
    }
  });
}

function serializeable (obj, propertyList, options) {
  options = options || {};
  options.transform = options.transform && options.transform.bind(obj);
  return Object.defineProperty(obj, 'serialize', {value:
    function (propertyList, options) {
      function getProperty (property) {
        if (property === 'this') {
          return serialize(this, options);
        }
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
  return serializeable({
    host: host,
    port: port
  }, ['host', 'port'], {separator: ':'});
}

function xparamsBuild (prop, propName, params, paramsName, combineOptions) {
  paramsName = paramsName || 'params';
  var ret = {};
  ret[propName] = prop;
  ret[paramsName] = combineParams(params, combineOptions);
  return serializeable(ret, [propName, paramsName]);
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

module.exports = {
  padInt: padInt
  ,joinEscaped: joinEscaped
  ,serializeable: serializeable
  ,hostportBuild: hostportBuild
  ,mapList: mapList
  ,combineParams: combineParams
  ,sipuriBuild: sipuriBuild
  ,addrparamsBuild: addrparamsBuild
  ,xparamsBuild: xparamsBuild
  ,defineDelimited: defineDelimited
  ,list: list
  ,header: header
};
