_ = require 'underscore'
marked = require 'marked'
Doc = require './doc'
{getLinkMatch, multiplyString} = require './utils'

SpecialHeadingDepth = 2
SpecialHeadings = ['Arguments', 'Events', 'Examples']

VisibilityRegex = '^\\s*([a-zA-Z]+):\\s*'
ReturnsRegex = "(#{VisibilityRegex})?\\s*Returns"
ArgumentListItemRegex = '^\\s*`([\\w\\.-]+)`(\\s*[:-])?\\s*'

###
Section: Parsing

Translating things from markdown into our json format.
###

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
    if args = parseArgumentsSection(tokens)
      doc.arguments = args
    else if events = parseEventsSection(tokens)
      doc.events = events
    else if examples = parseExamplesSection(tokens)
      doc.examples = examples
    else if returnValues = parseReturnValues(tokens)
      doc.setReturnValues(returnValues)
    else
      tokens.shift()

  doc

parseSummaryAndDescription = (tokens) ->
  summary = ''
  description = ''
  visibility = 'Private'

  rawVisibility = null
  rawSummary = tokens[0].text
  if rawSummary
    if visibilityMatch = new RegExp(VisibilityRegex).exec(rawSummary)
      visibility = visibilityMatch[1]
      rawVisibility = visibilityMatch[0]
      rawSummary = rawSummary.replace(rawVisibility, '')

  if isReturnValue(rawSummary)
    returnValues = parseReturnValues(tokens)
    {summary, description, visibility, returnValues}
  else
    summary = rawSummary
    description = generateDescription(tokens, stopOnSectionBoundaries)
    description = description.replace(rawVisibility, '') if rawVisibility?
    {description, summary, visibility}

parseArgumentsSection = (tokens) ->
  firstToken = _.first(tokens)
  if firstToken and firstToken.type in ['list_start', 'heading']
    return if firstToken.type == 'heading' and not (firstToken.text is 'Arguments' and firstToken.depth is SpecialHeadingDepth)
  else
    return

  section =
    description: ''

  if firstToken.type == 'list_start'
    section.list = parseArgumentList(tokens)
  else
    tokens.shift() # consume the header
    section.description = generateDescription(tokens, stopOnSectionBoundaries)
    section.list = parseArgumentList(tokens)

  section

parseEventsSection = (tokens) ->
  firstToken = _.first(tokens)
  return unless firstToken and firstToken.type == 'heading' and firstToken.text is 'Events' and firstToken.depth is SpecialHeadingDepth

  section =
    description: ''

  tokens.shift() # consume the header
  section.description = generateDescription(tokens, stopOnSectionBoundaries)
  section.list = parseArgumentList(tokens)

  section

parseExamplesSection = (tokens) ->
  firstToken = _.first(tokens)
  return unless firstToken and firstToken.type == 'heading' and firstToken.text is 'Examples' and firstToken.depth is SpecialHeadingDepth

  examples = []
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
      examples.push example
    else
      break

  examples if examples.length

parseReturnValues = (tokens) ->
  firstToken = _.first(tokens)
  return unless firstToken and firstToken.type in ['paragraph', 'text'] and isReturnValue(firstToken.text)

  token = tokens.shift()
  returnsMatches = new RegExp(ReturnsRegex).exec(token.text) # there might be a `Public: ` in front of the return.
  normalizedString = token.text.replace(returnsMatches[1], '').replace(/\n/g, ' ').replace(/\s{2,}/g, ' ')

  returnValues = null

  while normalizedString
    nextIndex = normalizedString.indexOf('Returns', 1)
    returnString = normalizedString
    if nextIndex > -1
      returnString = normalizedString.substring(0, nextIndex)
      normalizedString =  normalizedString.substring(nextIndex, normalizedString.length)
    else
      normalizedString = null

    returnValues ?= []
    returnValues.push
      type: getLinkMatch(returnString)
      description: returnString.trim()

  returnValues

# Parses argument lists like this one:
#
# * `something` A {Bool}
#   * `somethingNested` A nested object
parseArgumentList = (tokens) ->
  depth = 0
  args = []
  argumentsList = null
  argumentsListStack = []
  argument = null
  argumentStack = []

  while tokens.length and (tokens[0].type is 'list_start' or depth)
    token = tokens[0]
    switch token.type
      when 'list_start'
        depth++
        argumentsListStack.push argumentsList if argumentsList?
        argumentsList = []
        tokens.shift()

      when 'list_item_start', 'loose_item_start'
        argumentStack.push argument if argument?
        argument = {}
        tokens.shift()

      when 'code'
        argument.text ?= []
        argument.text.push '\n' + generateCode(tokens)

      when 'text'
        argument.text ?= []
        argument.text.push token.text
        tokens.shift()

      when 'list_item_end', 'loose_item_end'
        if argument?
          _.extend argument, parseListItem(argument.text.join(' '))
          argumentsList.push argument
          delete argument.text

        argument = argumentStack.pop()
        tokens.shift()

      when 'list_end'
        depth--
        if argument?
          argument.children = argumentsList
          argumentsList = argumentsListStack.pop()
        else
          args = argumentsList
        tokens.shift()

      else tokens.shift()

  args

parseListItem = (argumentString) ->
  name = null
  type = null
  description = argumentString

  if nameMatches = new RegExp(ArgumentListItemRegex).exec(argumentString)
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

isReturnValue = (string) ->
  new RegExp(ReturnsRegex).test(string)

stopOnSectionBoundaries = (token, tokens) ->
  if token.type in ['paragraph', 'text']
    return false if isReturnValue(token.text)

  else if token.type is 'heading'
    return false if token.depth == SpecialHeadingDepth and token.text in SpecialHeadings

  else if token.type is 'list_start'
    listToken = null
    for listToken in tokens
      break if listToken.type == 'text'

    # Check if list is an arguments list. If it starts with `someVar`, it is.
    return false if listToken? and new RegExp(ArgumentListItemRegex).test(listToken.text)

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
