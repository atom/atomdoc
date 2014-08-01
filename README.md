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

  It does things and stuff and even more things, this is the description.

  count - an {Int} representing count
  callback - a {Function} that will be called when finished

  Returns a {Bool}; true when it does the thing
"""
doc = AtomDoc.parse(docString)
```

`doc` will be an object:

```coffee
{
  status: 'Public',
  summary: 'My awesome method that does stuff.'
  description: 'My awesome method that does stuff.\nIt does things and stuff and even more things, this is the description.',
  arguments: [{
    name: 'count',
    description: 'an {Int} representing count',
    type: 'Int'
  }, {
    name: 'callback',
    description: 'a {Function} that will be called when finished',
    type: 'Function'
  }],
  returnValue: [{
    type: 'Bool',
    description: 'Returns a {Bool}; true when it does the thing'
  }],
  originalText: """
    Public: My awesome method that does stuff.

    It does things and stuff and even more things, this is the description.

    count - an {Int} representing count
    callback - a {Function} that will be called when finished

    Returns a {Bool}; true when it does the thing
  """
}
```

The parser was pulled out of [biscotto][biscotto]


[biscotto]:https://github.com/atom/biscotto/tree/master/src/nodes
