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
      expect(doc.sections).toEqual []
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
      expect(doc.sections).toEqual []
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
      expect(doc.sections).toEqual []

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
      expect(doc.sections).toEqual []

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
      expect(doc.sections).toEqual []

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
        expect(doc.sections).toEqual []

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
        expect(doc.arguments).toEqual [
          name: 'fn'
          description: 'A {Function} to call inside the transaction.'
          type: 'Function'
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

      expect(doc.arguments).toEqual [
        name: 'fn'
        description: 'A {Function} to call inside the transaction.'
        type: 'Function'
      ]

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

      expect(doc.arguments).toEqual [{
        name: 'options'
        description: "{Object} options hash \n```js\na = 1\n```"
        type: 'Object'
      }, {
        name: 'something'
        description: "{Object} something"
        type: 'Object'
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

      expect(doc.arguments).toEqual [{
        name: '1'
        description: 'one'
        type: null
        children: [{
          name: '1.1'
          description: 'two'
          type: null
        },{
          name: '1.2'
          description: 'three'
          type: null
          children: [{
            name: '1.2.1'
            description: 'four'
            type: null
          }]
        },{
          name: '1.3'
          description: 'five'
          type: null
        }]
      },{
        name: '2'
        description: 'six'
        type: null
      }]

    describe 'when there is an "Arguments" header', ->
      it "parses arguments without a description", ->
        str = """
          Public: Batch multiple operations as a single undo/redo step.

          ## Arguments

          * `something` A {Bool}
        """
        doc = parse(str)
        expect(doc.arguments).toEqual [
          name: 'something'
          description: 'A {Bool}'
          type: 'Bool'
        ]

      it "parses arguments with a description by ignoring the description", ->
        str = """
          Public: Batch multiple operations as a single undo/redo step.

          ## Arguments

          This should be ignored

          * `something` A {Bool}
        """
        doc = parse(str)
        expect(doc.arguments).toEqual [
          name: 'something'
          description: 'A {Bool}'
          type: 'Bool'
        ]

  describe 'events section', ->
    it "parses events without a description", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        * `something` A {Bool}

        ## Events

        ### contents-modified

        Fired when this thing happens.

        * `options` options hash
          * `anOption` true to do something
      """
      doc = parse(str)
      expect(doc.events).toEqual [
        name: 'contents-modified'
        summary: 'Fired when this thing happens.'
        description: 'Fired when this thing happens.'
        arguments: [
          name: 'options'
          description: 'options hash'
          type: null
          children: [
            name: 'anOption'
            description: 'true to do something'
            type: null
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

        Fired when this thing happens.

        This is a body of the thing

        * `options` options hash
      """
      doc = parse(str)
      expect(doc.events).toEqual [
        name: 'contents-modified'
        summary: 'Fired when this thing happens.'
        description: 'Fired when this thing happens.\n\nThis is a body of the thing'
        arguments: [
          name: 'options'
          description: 'options hash'
          type: null
        ]
      ]

    it "doesnt die when events section is messed up", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        ## Events

        * `options` options hash
      """
      doc = parse(str)
      expect(doc.events).toEqual null

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
      expect(doc.examples).toEqual [{
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
      expect(doc.examples).toEqual [{
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

  describe 'parsing returns', ->
    it "parses returns when there are arguments", ->
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
        description: 'Returns a {Bool} when X happens'
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

      expect(doc.returnValues).toEqual [{
        type: 'Bool'
        description: 'Returns a {Bool} when X happens'
      },{
        type: 'Function'
        description: 'Returns a {Function} when something else happens'
      },{
        type: 'Bool'
        description: 'Returns another {Bool} when Y happens'
      }]
