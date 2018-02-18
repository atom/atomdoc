const marked = require('marked')
const Doc = require('./doc')
const {getLinkMatch} = require('./utils')

const SpecialHeadingDepth = 2
const SpecialHeadings = /^Arguments|Events|Examples/

const VisibilityRegexStr = '^\\s*([a-zA-Z]+):\\s*'
const VisibilityRegex = new RegExp(VisibilityRegexStr)
const ReturnsRegex = new RegExp(`(${VisibilityRegexStr})?\\s*Returns`)
const ArgumentListItemRegex = /^\s*`([\w\\.-]+)`(\s*[:-])?(\s*\(optional\))?\s*/

/*
Section: Parsing

Translating things from markdown into our json format.
*/

// Public: Parses a docString
//
// * `docString` a string from the documented object to be parsed
//
// Returns a {Doc} object
const parse = function (docString) {
  const lexer = new marked.Lexer()
  const tokens = lexer.lex(docString)
  const firstToken = tokens[0]

  if (!firstToken || (firstToken.type !== 'paragraph')) {
    throw new Error('Doc string must start with a paragraph!')
  }

  const doc = new Doc(docString)

  Object.assign(doc, parseSummaryAndDescription(tokens))

  while (tokens.length) {
    let args, events, examples, returnValues, titledArgs
    if ((titledArgs = parseTitledArgumentsSection(tokens))) {
      if (doc.titledArguments == null) doc.titledArguments = []
      doc.titledArguments.push(titledArgs)
    } else if ((args = parseArgumentsSection(tokens))) {
      doc.arguments = args
    } else if ((events = parseEventsSection(tokens))) {
      doc.events = events
    } else if ((examples = parseExamplesSection(tokens))) {
      doc.examples = examples
    } else if ((returnValues = parseReturnValues(tokens, true))) {
      doc.setReturnValues(returnValues)
    } else {
      // These tokens are basically in no-mans land. We'll add them to the
      // description so they dont get lost.
      const extraDescription = generateDescription(tokens, stopOnSectionBoundaries)
      doc.description += `\n\n${extraDescription}`
    }
  }

  return doc
}

const parseSummaryAndDescription = function (tokens, tokenCallback) {
  if (tokenCallback == null) { tokenCallback = stopOnSectionBoundaries }
  let summary = ''
  let description = ''
  let visibility = 'Private'

  let rawVisibility = null
  let rawSummary = tokens[0].text
  if (rawSummary) {
    const visibilityMatch = VisibilityRegex.exec(rawSummary)
    if (visibilityMatch) {
      visibility = visibilityMatch[1]
      rawVisibility = visibilityMatch[0]
      if (rawVisibility) rawSummary = rawSummary.replace(rawVisibility, '')
    }
  }

  if (isReturnValue(rawSummary)) {
    const returnValues = parseReturnValues(tokens, false)
    return {summary, description, visibility, returnValues}
  } else {
    summary = rawSummary
    description = generateDescription(tokens, tokenCallback)
    if (rawVisibility) description = description.replace(rawVisibility, '')
    return {description, summary, visibility}
  }
}

const parseArgumentsSection = function (tokens) {
  const firstToken = tokens[0]
  if (firstToken && firstToken.type === 'heading') {
    if (firstToken.text !== 'Arguments' || firstToken.depth !== SpecialHeadingDepth) return
  } else if (firstToken && firstToken.type === 'list_start') {
    if (!isAtArgumentList(tokens)) { return }
  } else {
    return
  }

  let args = null

  if (firstToken.type === 'list_start') {
    args = parseArgumentList(tokens)
  } else {
    tokens.shift() // consume the header
    // consume any BS before the args list
    generateDescription(tokens, stopOnSectionBoundaries)
    args = parseArgumentList(tokens)
  }

  return args
}

const parseTitledArgumentsSection = function (tokens) {
  const firstToken = tokens[0]
  if (!firstToken || firstToken.type !== 'heading') return
  if (!firstToken.text.startsWith('Arguments:') ||
    firstToken.depth !== SpecialHeadingDepth
  ) {
    return
  }

  return {
    title: tokens.shift().text.replace('Arguments:', '').trim(),
    description: generateDescription(tokens, stopOnSectionBoundaries),
    arguments: parseArgumentList(tokens)
  }
}

const parseEventsSection = function (tokens) {
  let firstToken = tokens[0]
  if (
    !firstToken ||
    firstToken.type !== 'heading' ||
    firstToken.text !== 'Events' ||
    firstToken.depth !== SpecialHeadingDepth
  ) { return }

  const eventHeadingDepth = SpecialHeadingDepth + 1

  // We consume until there is a heading of h3 which denotes the beginning of an event.
  const stopTokenCallback = function (token, tokens) {
    if ((token.type === 'heading') && (token.depth === eventHeadingDepth)) {
      return false
    }
    return stopOnSectionBoundaries(token, tokens)
  }

  const events = []
  tokens.shift() // consume the header

  while (tokens.length) {
    // We consume until there is a heading of h3 which denotes the beginning of an event.
    generateDescription(tokens, stopTokenCallback)

    firstToken = tokens[0]
    if (
      firstToken &&
      firstToken.type === 'heading' &&
      firstToken.depth === eventHeadingDepth
    ) {
      tokens.shift() // consume the header
      const {summary, description, visibility} = parseSummaryAndDescription(
        tokens, stopTokenCallback)
      const name = firstToken.text
      let args = parseArgumentList(tokens)
      if (args.length === 0) args = null
      events.push({name, summary, description, visibility, arguments: args})
    } else {
      break
    }
  }

  if (events.length) { return events }
}

const parseExamplesSection = function (tokens) {
  let firstToken = tokens[0]
  if (
    !firstToken ||
    firstToken.type !== 'heading' ||
    firstToken.text !== 'Examples' ||
    firstToken.depth !== SpecialHeadingDepth
  ) { return }

  const examples = []
  tokens.shift() // consume the header

  while (tokens.length) {
    const description = generateDescription(tokens, function (token, tokens) {
      if (token.type === 'code') return false
      return stopOnSectionBoundaries(token, tokens)
    })

    firstToken = tokens[0]
    if (firstToken.type === 'code') {
      const example = {
        description,
        lang: firstToken.lang,
        code: firstToken.text,
        raw: generateCode(tokens)
      }
      examples.push(example)
    } else {
      break
    }
  }

  if (examples.length) { return examples }
}

const parseReturnValues = function (tokens, consumeTokensAfterReturn) {
  let normalizedString
  if (consumeTokensAfterReturn == null) { consumeTokensAfterReturn = false }
  const firstToken = tokens[0]
  if (
    !firstToken ||
    !['paragraph', 'text'].includes(firstToken.type) ||
    !isReturnValue(firstToken.text)
  ) { return }

  // there might be a `Public: ` in front of the return.
  const returnsMatches = ReturnsRegex.exec(firstToken.text)
  if (consumeTokensAfterReturn) {
    normalizedString = generateDescription(tokens, () => true)
    if (returnsMatches[1]) {
      normalizedString = normalizedString.replace(returnsMatches[1], '')
    }
  } else {
    const token = tokens.shift()
    normalizedString = token.text
    if (returnsMatches[1]) {
      normalizedString = normalizedString.replace(returnsMatches[1], '')
    }
    normalizedString = normalizedString.replace(/\s{2,}/g, ' ')
  }

  let returnValues = null

  while (normalizedString) {
    const nextIndex = normalizedString.indexOf('Returns', 1)
    let returnString = normalizedString
    if (nextIndex > -1) {
      returnString = normalizedString.substring(0, nextIndex)
      normalizedString = normalizedString.substring(nextIndex, normalizedString.length)
    } else {
      normalizedString = null
    }

    if (returnValues == null) { returnValues = [] }
    returnValues.push({
      type: getLinkMatch(returnString),
      description: returnString.trim()
    })
  }

  return returnValues
}

// Parses argument lists like this one:
//
// * `something` A {Bool}
//   * `somethingNested` A nested object
const parseArgumentList = function (tokens) {
  let depth = 0
  let args = []
  let argumentsList = null
  const argumentsListStack = []
  let argument = null
  const argumentStack = []

  while (tokens.length && (tokens[0].type === 'list_start' || depth)) {
    const token = tokens[0]
    switch (token.type) {
      case 'list_start':
        // This list might not be a argument list. Check...
        const parseAsArgumentList = isAtArgumentList(tokens)
        if (parseAsArgumentList) {
          depth++
          if (argumentsList) argumentsListStack.push(argumentsList)
          argumentsList = []
          tokens.shift()
        } else if (argument) {
          // If not, consume the list as part of the description
          if (!argument.text) argument.text = []
          argument.text.push(`\n${generateList(tokens)}`)
        }
        break

      case 'list_item_start':
      case 'loose_item_start':
        if (argument) { argumentStack.push(argument) }
        argument = {}
        tokens.shift()
        break

      case 'code':
        if (!argument.text) argument.text = []
        argument.text.push(`\n${generateCode(tokens)}`)
        break

      case 'text':
        if (!argument.text) argument.text = []
        argument.text.push(token.text)
        tokens.shift()
        break

      case 'list_item_end':
      case 'loose_item_end':
        if (argument) {
          Object.assign(argument,
            parseListItem(argument.text.join(' ').replace(/ \n/g, '\n')))
          argumentsList.push(argument)
          delete argument.text
        }

        argument = argumentStack.pop()
        tokens.shift()
        break

      case 'list_end':
        depth--
        if (argument) {
          argument.children = argumentsList
          argumentsList = argumentsListStack.pop()
        } else {
          args = argumentsList
        }
        tokens.shift()
        break

      default: tokens.shift()
    }
  }

  return args
}

const parseListItem = function (argumentString) {
  let isOptional
  let name = null
  let type = null
  let description = argumentString

  const nameMatches = ArgumentListItemRegex.exec(argumentString)
  if (nameMatches) {
    name = nameMatches[1]
    description = description.replace(nameMatches[0], '')
    type = getLinkMatch(description)
    isOptional = !!nameMatches[3]
  }

  return {name, description, type, isOptional}
}

module.exports = {parse}

/*
Section: Generation

These methods will consume tokens and return a markdown representation of the
tokens. Yeah, it generates markdown from the lexed markdown tokens.
*/

const isReturnValue = string => ReturnsRegex.test(string)

const isArgumentListItem = string => ArgumentListItemRegex.test(string)

const isAtArgumentList = function (tokens) {
  let foundListStart = false
  for (let token of tokens) {
    if (['list_item_start', 'loose_item_start'].includes(token.type)) {
      foundListStart = true
    } else if (token.type === 'text' && foundListStart) {
      return isArgumentListItem(token.text)
    }
  }
}

const stopOnSectionBoundaries = function (token, tokens) {
  if (['paragraph', 'text'].includes(token.type)) {
    if (isReturnValue(token.text)) {
      return false
    }
  } else if (token.type === 'heading') {
    if (token.depth === SpecialHeadingDepth && SpecialHeadings.test(token.text)) {
      return false
    }
  } else if (token.type === 'list_start') {
    let listToken = null
    for (listToken of tokens) {
      if (listToken.type === 'text') break
    }

    // Check if list is an arguments list. If it starts with `someVar`, it is.
    if (listToken && ArgumentListItemRegex.test(listToken.text)) return false
  }

  return true
}

// Will read / consume tokens down to a special section (args, events, examples)
const generateDescription = function (tokens, tokenCallback) {
  let token
  const description = []
  while ((token = tokens[0])) {
    if ((tokenCallback) && (tokenCallback(token, tokens) === false)) break

    if (['paragraph', 'text'].includes(token.type)) {
      description.push(generateParagraph(tokens))
    } else if (token.type === 'blockquote_start') {
      description.push(generateBlockquote(tokens))
    } else if (token.type === 'code') {
      description.push(generateCode(tokens))
    } else if (token.type === 'heading') {
      description.push(generateHeading(tokens))
    } else if (token.type === 'list_start') {
      description.push(generateList(tokens))
    } else if (token.type === 'space') {
      tokens.shift()
    } else {
      break
    }
  }

  return description.join('\n\n')
}

const generateParagraph = tokens => tokens.shift().text

const generateHeading = function (tokens) {
  const token = tokens.shift()
  return `${'#'.repeat(token.depth)} ${token.text}`
}

const generateBlockquote = function (tokens) {
  let token
  const lines = []

  while ((token = tokens.shift())) {
    if (token.type === 'blockquote_end') break
    if (token.text) {
      for (let line of token.text.split('\n')) {
        lines.push(`> ${line}`)
      }
    }
  }

  return lines.join('\n')
}

const generateCode = function (tokens) {
  const token = tokens.shift()
  const lines = []
  lines.push(token.lang ? `\`\`\`${token.lang}` : '```')
  lines.push(token.text)
  lines.push('```')
  return lines.join('\n')
}

const generateList = function (tokens) {
  let token
  let depth = -1
  const lines = []
  let linePrefix = null

  let ordered = null
  const orderedStack = []

  const indent = () => '  '.repeat(depth)

  while ((token = tokens[0])) {
    let textLines
    switch (token.type) {
      case 'list_start':
        depth++
        orderedStack.push(ordered);
        ({ ordered } = token)
        break

      case 'list_item_start':
      case 'loose_item_start':
        linePrefix = ordered ? `${indent()}1. ` : `${indent()}* `
        break

      case 'text':
      case 'code':
      case 'blockquote_start':
        if (token.type === 'code') {
          textLines = generateCode(tokens).split('\n')
        } else if (token.type === 'blockquote_start') {
          textLines = generateBlockquote(tokens).split('\n')
        } else {
          textLines = token.text.split('\n')
        }

        for (let line of textLines) {
          const prefix = linePrefix || `${indent()}  `
          lines.push(prefix + line)
          linePrefix = null
        } // we used the bullet!
        break

      case 'list_end':
        depth--
        ordered = orderedStack.pop()
        break
    }

    token = tokens.shift()
    if (depth < 0) break
  }

  return lines.join('\n')
}
