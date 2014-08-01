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

  _.extend doc, parseSummaryAndDescription(tokens)
  _.extend doc, parseArguments(tokens)

  doc

parseSummaryAndDescription = (tokens) ->
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
  description = description.join('\n\n')

  {description, summary, visibility}

parseArguments = (tokens) ->
  argumentTypes = [
    'list_start',
    'list_item_start', 'loose_item_start',
    'text', 'space'
    'loose_item_end', 'list_item_end'
    'list_end'
  ]

  args = []
  argumentsList = null
  argumentsListStack = []
  argument = null
  argumentStack = []
  while tokens.length and tokens[0].type in argumentTypes
    token = tokens.shift()
    switch token.type
      when 'list_start'
        argumentsList = []
        argumentsListStack.push argumentsList

      when 'list_item_start', 'loose_item_start'
        argument = {}
        argumentStack.push argument

      when 'text'
        argument.text ?= []
        argument.text.push token.text

      when 'list_item_end', 'loose_item_end'
        _.extend argument, parseArgument(argument.text.join(' '))
        argumentsList.push argument
        delete argument.text

        argumentStack.pop()
        argument = _.last argumentStack

      when 'list_end'
        if argument?
          argument.arguments = argumentsList
          argumentsListStack.pop()
          argumentsList = _.last argumentsListStack
        else
          args = argumentsList

  {arguments: args}

parseArgument = (argumentString) ->
  name = null
  type = null
  description = argumentString

  if nameMatches = /^\s*`([\w\.-]+)`(\s*[:-])?\s*/.exec(argumentString)
    name = nameMatches[1]
    description = description.replace(nameMatches[0], '')

  {name, description}

parseExamples = (tokens, doc) ->

parseEvents = (tokens, doc) ->

module.exports = {parse}
