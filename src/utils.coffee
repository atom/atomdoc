_ = require 'underscore'

module.exports =
  getLinkMatch: (text) ->
    if m = text.match(/\{([\w.]+)\}/)
      m[1]
    else
      null

  multiplyString: (string, times) ->
    ret = ''
    for i in [0...times]
      ret += string
    ret
