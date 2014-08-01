_ = require 'underscore'
marked = require 'marked'
Doc = require './doc'

# Public: Parses a docString
#
# * `docString` a string from the documented object to be parsed
#
# Returns a {Doc} object
parse = (docString) ->
  lexer = new marked.Lexer()
  tokens = lexer.lex(docString)
  doc = new Doc(docString)

  parseSummaryAndDescription(tokens, doc)

  doc

parseSummaryAndDescription = (tokens, doc) ->
  visibility = 'Private'
  summary = ''
  description = []

  while tokens.length and tokens[0].type == 'paragraph'
    token = tokens.shift()
    if summary
      description.push(token.text)
    else
      summary = token.text

  if summary
    if visibilityMatch = /^\s*([a-zA-Z]+):\s*/.exec(summary)
      visibility = visibilityMatch[1]
      summary = summary.replace(visibilityMatch[0], '')

  description.unshift(summary)
  doc.description = description.join('\n\n')
  doc.summary = summary
  doc.visibility = visibility

parseArguments = (tokens, doc) ->

parseExamples = (tokens, doc) ->

parseEvents = (tokens, doc) ->

module.exports = {parse}
