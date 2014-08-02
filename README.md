# AtomDoc parser

Parse atomdoc with JavaScript / CoffeeScript.

## Usage

It's on [npm](https://www.npmjs.org/package/atomdoc)

```
npm install atomdoc
```

It only has one method, `parse`, that takes no options.

```coffee
AtomDoc = require 'atomdoc'

docString = """
  Public: My awesome method that does stuff.

  It does things and stuff and even more things, this is the description. The
  next section is the arguments. They can be nested. Useful for explaining the
  arguments passed to any callbacks.

  * `count` An {Int} representing count
  * `callback` A {Function} that will be called when finished
    * `options` Options {Object} passed to your callback with the options:
      * `someOption` A {Bool}
      * `anotherOption` Another {Bool}

  ## Events

  The events section can have a description if you like.

  * `contents-modified` Fired when this thing happens.
    * `options` An options hash

  ## Examples

  This is an example. It can have a description

  ```coffee
  myMethod 20, ({someOption, anotherOption}) ->
    console.log someOption, anotherOption
  `` `

  Returns a {Bool}; true when it does the thing
"""
doc = AtomDoc.parse(docString)
```

`doc` will be an object:

```coffee
{
  "visibility": "Public",
  "summary": "My awesome method that does stuff.",
  "description": """
    My awesome method that does stuff.

    It does things and stuff and even more things, this is the description. The
    next section is the arguments. They can be nested. Useful for explaining the
    arguments passed to any callbacks.
  """
  "sections": [{
    "type": "arguments",
    "description": "",
    "arguments": [{
      "name": "count",
      "description": "An {Int} representing count",
      "type": "Int"
    },
    {
      "name": "callback"
      "description": "A {Function} that will be called when finished"
      "type": "Function"
      "arguments": [{
        "name": "options"
        "description": "Options {Object} passed to your callback with the options:"
        "type": "Object"
        "arguments": [{
          "name": "someOption",
          "description": "A {Bool}",
          "type": "Bool"
        },
        {
          "name": "anotherOption",
          "description": "Another {Bool}",
          "type": "Bool"
        }]
      }]
    }]
  },
  {
    "type": "events",
    "description": "The events section can have a description if you like.",
    "events": [{
      "name": "contents-modified"
      "description": "Fired when this thing happens."
      "type": null
      "arguments": [{
        "name": "options",
        "description": "An options hash",
        "type": null
      }]
    }]
  },
  {
    "type": "examples",
    "examples": [{
      "description": "This is an example. It can have a description",
      "lang": "coffee",
      "code": "myMethod 20, ({someOption, anotherOption}) ->\n  console.log someOption, anotherOption",
      "raw": "```coffee\nmyMethod 20, ({someOption, anotherOption}) ->\n  console.log someOption, anotherOption\n```"
    }]
  }],
  "returnValues": [{
    "type": "Bool",
    "description": "Returns a {Bool}; true when it does the thing"
  }]
}
```

The parser uses [marked]'s lexer.


[marked]:https://github.com/chjj/marked
