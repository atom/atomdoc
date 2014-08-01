_ = require 'underscore'
# _.str = require 'underscore.string'

module.exports =
  getLinkMatch: (text) ->
    if m = text.match(/\{([\w.]+)\}/)
      m[1]
    else
      null

  # Internal: Deindents excess whitespace from the sections.
  #
  # lines - An {Array} of {String}s
  #
  # Returns `lines` with the leftmost whitespace removed.
  deindent: (lines) ->
    # remove indention
    spaces = _.map lines, (line) ->
      return line if _.isEmpty(_.str.strip(line))
      md = line.match(/^(\s*)/)
      if md then md[1].length else null
    spaces = _.compact(spaces)
    space = _.min(spaces) || 0
    _.map lines, (line) ->
      if _.isEmpty(line)
        _.str.strip(line)
      else
        line[space..-1]

  # Detect whitespace on the left and removes the minimum whitespace amount.
  # This will keep indention for examples intact.
  #
  # lines - The comment lines [{String}]
  #
  # Returns the left trimmed lines as an {Array} of {String}s.
  leftTrimBlock: (lines) ->
    # Detect minimal left trim amount
    trimMap = _.map lines, (line) ->
      if line.length is 0
        undefined
      else
        line.length - _.str.ltrim(line).length

    minimalTrim = _.min _.without(trimMap, undefined)

    # If we have a common amount of left trim
    if minimalTrim > 0 and minimalTrim < Infinity
      # Trim same amount of left space on each line
      lines = for line in lines
        line = line.substring(minimalTrim, line.length)
        line

    lines
