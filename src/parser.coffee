_ = require 'underscore'
marked = require 'marked'
Doc = require './doc'
{getLinkMatch, multiplyString} = require './utils'

SpecialHeadingDepth = 2
SpecialHeadings = ['Arguments', 'Events', 'Examples']

# Public: Parses a docString
#
# * `docString` a string from the documented object to be parsed
#
# Returns a {Doc} object
parse = (docString) ->
  lexer = new marked.Lexer()
  tokens = lexer.lex(docString)
  firstToken = _.first(tokens)

  unless firstToken and firstToken.type == 'paragraph'
    throw new Error 'Doc string must start with a paragraph!'

  doc = new Doc(docString)

  _.extend doc, parseSummaryAndDescription(tokens)

  while tokens.length
    section = null
    section ?= parseArgumentsSection(tokens)
    section ?= parseEventsSection(tokens)
    section ?= parseExamplesSection(tokens)

    if section?
      doc.addSection(section)
    else
      tokens.shift()

  doc

parseSummaryAndDescription = (tokens) ->
  visibility = 'Private'
  summary = tokens.shift().text
  description = generateDescription(tokens, stopOnSectionBoundaries)

  if summary
    if visibilityMatch = /^\s*([a-zA-Z]+):\s*/.exec(summary)
      visibility = visibilityMatch[1]
      summary = summary.replace(visibilityMatch[0], '')

  description = if description then "#{summary}\n\n#{description}" else summary

  {description, summary, visibility}

parseArgumentsSection = (tokens) ->
  firstToken = _.first(tokens)
  if firstToken and firstToken.type in ['list_start', 'heading']
    return if firstToken.type == 'heading' and not (firstToken.text is 'Arguments' and firstToken.depth is SpecialHeadingDepth)
  else
    return

  section =
    type: 'arguments'
    description: ''

  if firstToken.type == 'list_start'
    section.arguments = parseArgumentList(tokens)
  else
    tokens.shift() # consume the header
    section.description = generateDescription(tokens, stopOnSectionBoundaries)
    section.arguments = parseArgumentList(tokens)

  section

parseEventsSection = (tokens) ->
  firstToken = _.first(tokens)
  return unless firstToken and firstToken.type == 'heading' and firstToken.text is 'Events' and firstToken.depth is SpecialHeadingDepth

  section =
    type: 'events'
    description: ''

  tokens.shift() # consume the header
  section.description = generateDescription(tokens, stopOnSectionBoundaries)
  section.events = parseArgumentList(tokens)

  section

parseExamplesSection = (tokens) ->
  firstToken = _.first(tokens)
  return unless firstToken and firstToken.type == 'heading' and firstToken.text is 'Examples' and firstToken.depth is SpecialHeadingDepth

  section =
    type: 'examples'
    examples: []

  tokens.shift() # consume the header

  while tokens.length
    description = generateDescription tokens, (token, tokens) ->
      return false if token.type is 'code'
      stopOnSectionBoundaries(token, tokens)

    firstToken = _.first(tokens)
    if firstToken.type is 'code'
      example =
        description: description
        lang: firstToken.lang
        code: firstToken.text
        raw: generateCode(tokens)
      section.examples.push example
    else
      break

  section if section.examples.length

parseArgumentList = (tokens) ->
  ArgumentListTokenTypes = [
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
  while tokens.length and tokens[0].type in ArgumentListTokenTypes
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
        _.extend argument, parseListItem(argument.text.join(' '))
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

  args

parseListItem = (argumentString) ->
  name = null
  type = null
  description = argumentString

  if nameMatches = /^\s*`([\w\.-]+)`(\s*[:-])?\s*/.exec(argumentString)
    name = nameMatches[1]
    description = description.replace(nameMatches[0], '')
    type = getLinkMatch(description)

  {name, description, type}

module.exports = {parse}

###
Section: Generation

These methods will consume tokens and return a markdown representation of the
tokens. Yeah, it generates markdown from the lexed markdown tokens.
###

stopOnSectionBoundaries = (token, tokens) ->
  if token.type is 'heading'
    return false if token.depth == SpecialHeadingDepth and token.text in SpecialHeadings

  else if token.type is 'list_start'
    listToken = null
    for listToken in tokens
      break if listToken.type == 'text'

    # Check if list is an arguments list. If it starts with `someVar`, it is.
    return false if listToken? and /^\s*`([\w\.-]+)`/.test(listToken.text)

# Will read / consume tokens down to a special section (args, events, examples)
generateDescription = (tokens, tokenCallback) ->
  description = []
  while token = _.first(tokens)
    break if tokenCallback? and tokenCallback(token, tokens) == false

    if token.type in ['paragraph', 'text']
      description.push generateParagraph(tokens)

    else if token.type is 'blockquote_start'
      description.push generateBlockquote(tokens)

    else if token.type is 'code'
      description.push generateCode(tokens)

    else if token.type is 'heading'
      description.push generateHeading(tokens)

    else if token.type is 'list_start'
      description.push generateList(tokens)

    else break

  description.join '\n\n'

generateParagraph = (tokens) ->
  tokens.shift().text

generateHeading = (tokens) ->
  token = tokens.shift()
  "#{multiplyString('#', token.depth)} #{token.text}"

generateBlockquote = (tokens) ->
  lines = []

  while token = tokens.shift()
    break if token.type is 'blockquote_end'
    if token.text?
      for line in token.text.split('\n')
        lines.push "> #{line}"

  lines.join '\n'

generateCode = (tokens) ->
  token = tokens.shift()
  lines = []
  lines.push if token.lang? then "```#{token.lang}" else '```'
  lines.push token.text
  lines.push '```'
  lines.join '\n'

generateList = (tokens) ->
  depth = -1
  lines = []
  linePrefix = null

  ordered = null
  orderedStack = []

  indent = ->
    multiplyString('  ', depth)

  while token = _.first(tokens)
    switch token.type
      when 'list_start'
        depth++
        orderedStack.push ordered
        ordered = token.ordered

      when 'list_item_start', 'loose_item_start'
        linePrefix = if ordered then "#{indent()}1. " else "#{indent()}* "

      when 'text', 'code', 'blockquote_start'
        if token.type == 'code'
          textLines = generateCode(tokens).split('\n')
        else if token.type == 'blockquote_start'
          textLines = generateBlockquote(tokens).split('\n')
        else
          textLines = token.text.split('\n')

        for line in textLines
          prefix = linePrefix ? "#{indent()}  "
          lines.push prefix + line
          linePrefix = null # we used the bullet!

      when 'list_end'
        depth--
        ordered = orderedStack.pop()

    token = tokens.shift()
    break if depth < 0

  lines.join '\n'
