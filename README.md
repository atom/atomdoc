# AtomDoc parser
[![OS X Build Status](https://travis-ci.org/atom/atomdoc.svg?branch=master)](https://travis-ci.org/atom/atomdoc)
[![Windows Build Status](https://ci.appveyor.com/api/projects/status/chi2bmaafr3puyq2/branch/master?svg=true)](https://ci.appveyor.com/project/Atom/atomdoc/branch/master)
[![Dependency Status](https://david-dm.org/atom/atomdoc.svg)](https://david-dm.org/atom/atomdoc)

Parse atomdoc with JavaScript / CoffeeScript.

Atomdoc is a code documentation format based on markdown. The atom team writes a lot of markdown, and its rules are deep in our brains. So rather than adopting some other format we'd need to learn, we decided to build a parser around a few markdown conventions.

## Usage

It's on [npm](https://www.npmjs.org/package/atomdoc).

```
npm install atomdoc
```

It has only one method, `parse`, which takes no options.

```coffee
AtomDoc = require 'atomdoc'

docString = """
  Public: My awesome method that does stuff, but returns nothing and has
  no arguments.
"""
doc = AtomDoc.parse(docString)
```

`doc` will be an object:

```coffee
{
  "visibility": "Public",
  "description": "My awesome method that does stuff, but returns nothing and has\nno arguments.",
  "summary": "My awesome method that does stuff, but returns nothing and has\nno arguments."
}
```

### Maximal example

Using all the features.

```coffee
AtomDoc = require 'atomdoc'

docString = """
    Public: My awesome method that does stuff.

    It does things and stuff and even more things, this is the description. The
    next section is the arguments. They can be nested. Useful for explaining the
    arguments passed to any callbacks.

    * `count` {Number} representing count
    * `callback` {Function} that will be called when finished
      * `options` Options {Object} passed to your callback with the options:
        * `someOption` A {Bool}
        * `anotherOption` Another {Bool}

    ## Events

    ### contents-modified

    Public: Fired when this thing happens.

    * `options` {Object} An options hash
      * `someOption` {Object} An options hash

    ## Examples

    This is an example. It can have a description.

    ```coffee
    myMethod 20, ({someOption, anotherOption}) ->
      console.log someOption, anotherOption
    ```

    Returns null in some cases
    Returns an {Object} with these keys:
      * `someBool` a {Boolean}
      * `someNumber` a {Number}
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
  """,
  "arguments": [
    {
      "name": "count",
      "description": "{Number} representing count",
      "type": "Number",
      "isOptional": false
    },
    {
      "children": [
        {
          "name": "options",
          "description": "Options {Object} passed to your callback with the options:",
          "type": "Object",
          "isOptional": false
          "children": [
            {
              "name": "someOption",
              "description": "A {Bool}",
              "type": "Bool",
              "isOptional": false
            },
            {
              "name": "anotherOption",
              "description": "Another {Bool}",
              "type": "Bool",
              "isOptional": false
            }
          ],
        }
      ],
      "name": "callback",
      "description": "{Function} that will be called when finished",
      "type": "Function",
      "isOptional": false
    }
  ],
  "events": [
    {
      "name": "contents-modified",
      "summary": "Fired when this thing happens.",
      "description": "Fired when this thing happens.",
      "visibility": "Public",
      "arguments": [
        {
          "children": [
            {
              "name": "someOption",
              "description": "{Object} An options hash",
              "type": "Object",
              "isOptional": false
            }
          ],
          "name": "options",
          "description": "{Object} An options hash",
          "type": "Object",
          "isOptional": false
        }
      ]
    }
  ],
  "examples": [
    {
      "description": "This is an example. It can have a description",
      "lang": "coffee",
      "code": "myMethod 20, ({someOption, anotherOption}) ->\n  console.log someOption, anotherOption",
      "raw": "```coffee\nmyMethod 20, ({someOption, anotherOption}) ->\n  console.log someOption, anotherOption\n```"
    }
  ],
  "returnValues": [
    {
      "type": null,
      "description": "Returns null in some case"
    },
    {
      "type": "Object",
      "description": "Returns an {Object} with the keys:\n\n* `someBool` a {Boolean}\n* `someNumber` a {Number}"
    }
  ]
}
```

## Notes

The parser uses [marked][marked]'s lexer.


[marked]: https://github.com/chjj/marked
