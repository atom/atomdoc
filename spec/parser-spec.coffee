require 'jasmine-json'
{parse} = require '../src/parser'

describe "parser", ->
  describe 'summary and description', ->
    it "parses a simple one liner", ->
      str = "Public: Batch multiple operations as a single undo/redo step."
      doc = parse(str)

      expect(doc.visibility).toBe 'Public'
      expect(doc.summary).toBe 'Batch multiple operations as a single undo/redo step.'
      expect(doc.description).toBe 'Batch multiple operations as a single undo/redo step.'
      expect(doc.returnValue).not.toBeDefined()
      expect(doc.examples).not.toBeDefined()
      expect(doc.delegation).not.toBeDefined()

    it "parses the description properly", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        Here is some description.
      """
      doc = parse(str)

      expect(doc.visibility).toBe 'Public'
      expect(doc.summary).toBe 'Batch multiple operations as a single undo/redo step.'
      expect(doc.description).toBe """
        Batch multiple operations as a single undo/redo step.

        Here is some description.
      """
      expect(doc.returnValue).not.toBeDefined()
      expect(doc.examples).not.toBeDefined()
      expect(doc.delegation).not.toBeDefined()

    it "parses the description when there are code blocks", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        ```coffee
        a = 23
        ```

        Here is some description.

        ```
        for a in [1, 2, 3]
        ```
      """
      doc = parse(str)

      expect(doc.visibility).toBe 'Public'
      expect(doc.summary).toBe 'Batch multiple operations as a single undo/redo step.'
      expect(doc.description).toBe """
        Batch multiple operations as a single undo/redo step.

        ```coffee
        a = 23
        ```

        Here is some description.

        ```
        for a in [1, 2, 3]
        ```
      """

    it "parses the description when there are headings", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.


        ## Ok, computer

        Do your thing
      """
      doc = parse(str)

      expect(doc.visibility).toBe 'Public'
      expect(doc.summary).toBe 'Batch multiple operations as a single undo/redo step.'
      expect(doc.description).toBe """
        Batch multiple operations as a single undo/redo step.

        ## Ok, computer

        Do your thing
      """

    it "parses the description when there are blockquotes", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.


        > this is a quote
        > another one

        Do your thing

        > a second block
      """
      doc = parse(str)

      expect(doc.visibility).toBe 'Public'
      expect(doc.summary).toBe 'Batch multiple operations as a single undo/redo step.'
      expect(doc.description).toBe """
        Batch multiple operations as a single undo/redo step.

        > this is a quote
        > another one

        Do your thing

        > a second block
      """

    describe 'when there are lists in the description', ->
      it "parses the description when there are lists that are not arg lists", ->
        str = """
          Public: Batch multiple operations as a single undo/redo step.

          * one
            * two
              ```coffee
              ok = 1
              ```
            * This one has a blockquote, wtf?!
              > something
              > fuuu
          * someotherArg

          blah

          * one
            1. two
            1. three
              * four
            1. five
          * six

          Painful.
        """
        doc = parse(str)

        expect(doc.visibility).toBe 'Public'
        expect(doc.summary).toBe 'Batch multiple operations as a single undo/redo step.'
        expect(doc.description).toBe """
          Batch multiple operations as a single undo/redo step.

          * one
            * two
              ```coffee
              ok = 1
              ```
            * This one has a blockquote, wtf?!
              > something
              > fuuu
          * someotherArg

          blah

          * one
            1. two
            1. three
              * four
            1. five
          * six

          Painful.
        """

      it "description lists do not interfere with the arguments", ->
        str = """
          Public: Batch multiple operations as a single undo/redo step.

          * one
          * two

          Rainbows

          * `fn` A {Function} to call inside the transaction.
        """
        doc = parse(str)

        expect(doc.visibility).toBe 'Public'
        expect(doc.summary).toBe 'Batch multiple operations as a single undo/redo step.'
        expect(doc.description).toBe """
          Batch multiple operations as a single undo/redo step.

          * one
          * two

          Rainbows
        """
        expect(doc.arguments).toEqualJson [
          name: 'fn'
          description: 'A {Function} to call inside the transaction.'
          type: 'Function'
          isOptional: false
        ]

    describe "with different visibilities", ->
      it "parses a public visibility", ->
        doc = parse("Public: Batch multiple operations as a single undo/redo step.")
        expect(doc.visibility).toBe 'Public'
        expect(doc.isPublic()).toBe true

      it "parses Essential visibility", ->
        doc = parse("Essential: Batch multiple operations as a single undo/redo step.")
        expect(doc.visibility).toBe 'Essential'
        expect(doc.isPublic()).toBe true

      it "parses a private visibility", ->
        doc = parse("Private: Batch multiple operations as a single undo/redo step.")
        expect(doc.visibility).toBe 'Private'
        expect(doc.isPublic()).toBe false

      it "parses an internal visibility", ->
        doc = parse("Internal: Batch multiple operations as a single undo/redo step.")
        expect(doc.visibility).toBe 'Internal'
        expect(doc.isPublic()).toBe false

      it "parses no visibility", ->
        doc = parse("Batch multiple operations as a single undo/redo step.")
        expect(doc.visibility).toBe 'Private'
        expect(doc.isPublic()).toBe false

  describe 'arguments', ->
    it "parses single level arguments", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        * `fn` A {Function} to call inside the transaction.
      """
      doc = parse(str)

      expect(doc.arguments).toEqualJson [
        name: 'fn'
        description: 'A {Function} to call inside the transaction.'
        type: 'Function'
        isOptional: false
      ]

    it "parses optional arguments", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        * `index` {Int} index
        * `fn` (optional) A {Function} to call inside the transaction.
      """
      doc = parse(str)

      expect(doc.arguments).toEqualJson [{
        name: 'index'
        description: '{Int} index'
        type: 'Int'
        isOptional: false
      }, {
        name: 'fn'
        description: 'A {Function} to call inside the transaction.'
        type: 'Function'
        isOptional: true
      }]

    it "parses names with all the accepted characters", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        * `oneTWO3.4-5_6` A {Function} to call inside the transaction.
      """
      doc = parse(str)

      expect(doc.arguments[0].name).toEqual 'oneTWO3.4-5_6'

    it "parses arguments with code blocks", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        * `options` {Object} options hash
          ```js
          a = 1
          ```
        * `something` {Object} something
      """
      doc = parse(str)

      expect(doc.arguments).toEqualJson [{
        name: 'options'
        description: "{Object} options hash\n```js\na = 1\n```"
        type: 'Object'
        isOptional: false
      }, {
        name: 'something'
        description: "{Object} something"
        type: 'Object'
        isOptional: false
      }]

    it 'parses non-argument sublists as description', ->
      str = """
        Public: Create a marker with the given range.

        * `range` {Range}
        * `properties` A hash of key-value pairs
          * __never__: The marker is never marked as invalid.
          * __surround__: The marker is invalidated by changes that completely surround it.

        Returns a {Marker}
      """
      doc = parse(str)

      expect(doc.arguments).toEqualJson [{
        name: 'range'
        description: "{Range}"
        type: 'Range'
        isOptional: false
      }, {
        name: 'properties'
        description: """
          A hash of key-value pairs
          * __never__: The marker is never marked as invalid.
          * __surround__: The marker is invalidated by changes that completely surround it.
        """
        type: null
        isOptional: false
      }]

    it "handles nested arguments", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        * `1` one
          * `1.1` two
          * `1.2` three
            * `1.2.1` four
          * `1.3` five
        * `2` six
      """
      doc = parse(str)

      expect(doc.arguments).toEqualJson [{
        name: '1'
        description: 'one'
        type: null
        isOptional: false
        children: [{
          name: '1.1'
          description: 'two'
          type: null
          isOptional: false
        },{
          name: '1.2'
          description: 'three'
          type: null
          isOptional: false
          children: [{
            name: '1.2.1'
            description: 'four'
            type: null
            isOptional: false
          }]
        },{
          name: '1.3'
          description: 'five'
          type: null
          isOptional: false
        }]
      },{
        name: '2'
        description: 'six'
        type: null
        isOptional: false
      }]

    it "parses out an 'extra' description after the arguments", ->
      str = """
        Public: Invoke the given callback when all marker `::onDidChange`
        observers have been notified following a change to the buffer.

        * `callback` {Function} to be called after markers are updated.

        The order of events following a buffer change is as follows:

        * The text of the buffer is changed
        * All markers are updated accordingly, but their `::onDidChange` observers
          are not notified.

        This is some more extra description

        Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
      """
      doc = parse(str)
      expect(doc.description).toEqualJson  """
        Invoke the given callback when all marker `::onDidChange`
        observers have been notified following a change to the buffer.

        The order of events following a buffer change is as follows:

        * The text of the buffer is changed
        * All markers are updated accordingly, but their `::onDidChange` observers
          are not notified.

        This is some more extra description
      """
      expect(doc.arguments).toEqualJson  [
        "name": "callback",
        "description": "{Function} to be called after markers are updated.",
        "type": "Function",
        "isOptional": false
      ]

    describe 'when there is an "Arguments" header', ->
      it "parses arguments without a description", ->
        str = """
          Public: Batch multiple operations as a single undo/redo step.

          ## Arguments

          * `something` A {Bool}
        """
        doc = parse(str)
        expect(doc.arguments).toEqualJson [
          name: 'something'
          description: 'A {Bool}'
          type: 'Bool'
          isOptional: false
        ]

      it "parses arguments with a description by ignoring the description", ->
        str = """
          Public: Batch multiple operations as a single undo/redo step.

          ## Arguments

          This should be ignored

          * `something` A {Bool}
        """
        doc = parse(str)
        expect(doc.arguments).toEqualJson [
          name: 'something'
          description: 'A {Bool}'
          type: 'Bool'
          isOptional: false
        ]

    describe 'when there are multiple "Arguments" headers describing different forms of the method', ->
      it "parses arguments without a description", ->
        str = """
          Public: Batch multiple operations as a single undo/redo step.

          ## Arguments: Form one

          * `something` A {Bool}

          ## Arguments: Form two

          Some description here.

          * `somethingElse` A {String}
        """
        doc = parse(str)
        expect(doc.arguments).toBeUndefined()
        expect(doc.titledArguments).toEqualJson [{
          title: 'Form one'
          description: ''
          arguments: [
            name: 'something'
            description: 'A {Bool}'
            type: 'Bool'
            isOptional: false
          ]
        },{
          title: 'Form two'
          description: 'Some description here.'
          arguments: [
            name: 'somethingElse'
            description: 'A {String}'
            type: 'String'
            isOptional: false
          ]
        }]

  describe 'events section', ->
    it "parses events with nested arguments", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        * `something` A {Bool}

        ## Events

        ### contents-modified

        Essential: Fired when this thing happens.

        * `options` options hash
          * `anOption` true to do something
      """
      doc = parse(str)
      expect(doc.events).toEqualJson [
        name: 'contents-modified'
        summary: 'Fired when this thing happens.'
        description: 'Fired when this thing happens.'
        visibility: 'Essential'
        arguments: [
          name: 'options'
          description: 'options hash'
          type: null
          isOptional: false
          children: [
            name: 'anOption'
            description: 'true to do something'
            type: null
            isOptional: false
          ]
        ]
      ]

    it "parses events with a description", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        ## Arguments

        Some description

        * `something` A {Bool}

        ## Events

        Events do this and that and this too.

        ### contents-modified

        Public: Fired when this thing happens.

        This is a body of the thing

        * `options` options hash
      """
      doc = parse(str)
      expect(doc.events).toEqualJson [
        name: 'contents-modified'
        summary: 'Fired when this thing happens.'
        description: 'Fired when this thing happens.\n\nThis is a body of the thing'
        visibility: 'Public'
        arguments: [
          name: 'options'
          description: 'options hash'
          type: null
          isOptional: false
        ]
      ]

    describe 'when there are no options specified', ->
      it "parses multiple events with no options", ->
        str = """
          Public: Batch multiple operations as a single undo/redo step.

          ## Events

          ### contents-modified

          Public: Fired when this thing happens.

          This is a body of the thing

          ### another-event

          Public: Another
        """
        doc = parse(str)
        expect(doc.events).toEqualJson [{
          name: 'contents-modified'
          summary: 'Fired when this thing happens.'
          description: 'Fired when this thing happens.\n\nThis is a body of the thing'
          visibility: 'Public'
          arguments: null
        }, {
          name: 'another-event'
          summary: 'Another'
          description: 'Another'
          visibility: 'Public'
          arguments: null
        }]

    describe 'when there should be no output', ->
      it "doesnt die when events section is messed up", ->
        str = """
          Public: Batch multiple operations as a single undo/redo step.

          ## Events

          * `options` options hash
        """
        doc = parse(str)
        expect(doc.events).toEqual null

  describe 'examples section', ->
    it "parses Examples with a description", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        * `something` A {Bool}

        ## Examples

        This is example one

        ```coffee
        ok = 1
        ```

        This is example two

        ```coffee
        ok = 2
        ```
      """
      doc = parse(str)
      expect(doc.examples).toEqualJson [{
        description: 'This is example one'
        code: 'ok = 1'
        lang: 'coffee'
        raw: """
        ```coffee
        ok = 1
        ```
        """
      },{
        description: 'This is example two'
        code: 'ok = 2'
        lang: 'coffee'
        raw: """
        ```coffee
        ok = 2
        ```
        """
      }]

    it "parses Examples without a description", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        * `something` A {Bool}

        ## Examples

        ```coffee
        ok = 1
        ```

        ```coffee
        ok = 2
        ```
      """
      doc = parse(str)
      expect(doc.examples).toEqualJson [{
        description: ''
        code: 'ok = 1'
        lang: 'coffee'
        raw: """
        ```coffee
        ok = 1
        ```
        """
      },{
        description: ''
        code: 'ok = 2'
        lang: 'coffee'
        raw: """
        ```coffee
        ok = 2
        ```
        """
      }]

    it "ignores examples when no examples specified", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        * `something` A {Bool}

        ## Examples
      """
      doc = parse(str)
      expect(doc.examples).not.toBeDefined()

    describe 'when there is an events section above the examples section', ->
      it "parses out both the Events and Examples sections", ->
        str = """
          Public: Batch multiple operations as a single undo/redo step.

          ## Events

          Events do this and that and this too.

          ### contents-modified

          Public: Fired when this thing happens.

          ## Examples

          This is example one

          ```coffee
          ok = 1
          ```
        """
        doc = parse(str)
        expect(doc.events).toEqualJson [
          name: 'contents-modified'
          summary: 'Fired when this thing happens.'
          description: 'Fired when this thing happens.'
          visibility: 'Public'
          arguments: null
        ]
        expect(doc.examples).toEqualJson [
          description: 'This is example one'
          code: 'ok = 1'
          lang: 'coffee'
          raw: """
          ```coffee
          ok = 1
          ```
          """
        ]

  describe 'parsing returns', ->
    describe 'when there are arguments', ->
      it "parses returns when the arguments are before the return", ->
        str = """
          Public: Batch multiple operations as a single undo/redo step.

          * `fn` A {Function} to call inside the transaction.

          Returns a {Bool}
        """
        doc = parse(str)

        expect(doc.arguments).toEqualJson [
          name: 'fn'
          description: 'A {Function} to call inside the transaction.'
          type: 'Function'
          isOptional: false
        ]

        expect(doc.returnValues).toEqualJson [{
          type: 'Bool'
          description: 'Returns a {Bool}'
        }]

      it "parses returns when the return is the body and the args are after the return", ->
        str = """
          Public: Returns a {Bool}

          * `fn` A {Function} to call inside the transaction.
        """
        doc = parse(str)

        expect(doc.arguments).toEqualJson [
          name: 'fn'
          description: 'A {Function} to call inside the transaction.'
          type: 'Function'
          isOptional: false
        ]

        expect(doc.returnValues).toEqualJson [{
          type: 'Bool'
          description: 'Returns a {Bool}'
        }]

    it "parses returns when they span multiple lines", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        Returns a {Bool} when
          X happens
        Returns a {Function} when something else happens
      """
      doc = parse(str)

      expect(doc.returnValues).toEqualJson [{
        type: 'Bool'
        description: 'Returns a {Bool} when\n  X happens'
      },{
        type: 'Function'
        description: 'Returns a {Function} when something else happens'
      }]

    it 'parses returns when there is no description', ->
      str = """
        Public: Returns {Bool} true when Y happens
      """
      doc = parse(str)

      expect(doc.summary).toEqual ''
      expect(doc.description).toEqual ''
      expect(doc.returnValues).toEqualJson [{
        type: 'Bool'
        description: 'Returns {Bool} true when Y happens'
      }]

    it "parses returns when they break paragraphs", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        Returns a {Bool} when
          X happens
        Returns a {Function} when something else happens

        Returns another {Bool} when Y happens
      """
      doc = parse(str)

      expect(doc.returnValues).toEqualJson [{
        type: 'Bool'
        description: 'Returns a {Bool} when\n  X happens'
      },{
        type: 'Function'
        description: 'Returns a {Function} when something else happens'
      },{
        type: 'Bool'
        description: 'Returns another {Bool} when Y happens'
      }]

    it "parses return when it contains a list", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        Returns an {Object} with params:
          * `one` does stuff
          * `two` does more stuff
        Returns null when nothing happens
        Returns other when this code is run

        ```coffee
        a = something()
        ```
      """
      doc = parse(str)

      expect(doc.returnValues).toEqualJson [{
        type: 'Object'
        description: """
          Returns an {Object} with params:

          * `one` does stuff
          * `two` does more stuff
        """
      }, {
        type: null
        description: 'Returns null when nothing happens'
      }, {
        type: null
        description: """
          Returns other when this code is run

          ```coffee
          a = something()
          ```
        """
      }]
    it "parses return when it contains the keyword undefined", ->
      str = """
         Public: Get the active {Package} with the given name.

         Returns undefined.
      """
      doc = parse(str)

      expect(doc.returnValues).toEqualJson [{
        type: null,
        description: """
          Returns undefined.
        """
      }]
