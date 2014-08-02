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
        expect(doc.sections[0]).toEqual
          type: 'arguments'
          description: ''
          arguments: [
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

      expect(doc.sections[0]).toEqual
        type: 'arguments'
        description: ''
        arguments: [
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

      expect(doc.sections[0].arguments[0].name).toEqual 'oneTWO3.4-5_6'

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

      expect(doc.sections[0]).toEqual
        type: 'arguments'
        description: ''
        arguments: [{
          name: '1'
          description: 'one'
          type: null
          arguments:[{
            name: '1.1'
            description: 'two'
            type: null
          },{
            name: '1.2'
            description: 'three'
            type: null
            arguments: [{
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
        expect(doc.sections[0]).toEqual
          type: 'arguments'
          description: ''
          arguments: [
            name: 'something'
            description: 'A {Bool}'
            type: 'Bool'
          ]

      it "parses arguments with a description", ->
        str = """
          Public: Batch multiple operations as a single undo/redo step.

          ## Arguments

          Some description

          * `something` A {Bool}
        """
        doc = parse(str)
        expect(doc.sections[0]).toEqual
          type: 'arguments'
          description: 'Some description'
          arguments: [
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

        * `contents-modified` Fired when this thing happens.
          * `options` options hash
      """
      doc = parse(str)
      expect(doc.sections[1]).toEqual
        type: 'events'
        description: ''
        events: [
          name: 'contents-modified'
          description: 'Fired when this thing happens.'
          type: null
          arguments: [
            name: 'options'
            description: 'options hash'
            type: null
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

        * `contents-modified` Fired when this thing happens.
          * `options` options hash
      """
      doc = parse(str)
      expect(doc.sections[1]).toEqual
        type: 'events'
        description: 'Events do this and that and this too.'
        events: [
          name: 'contents-modified'
          description: 'Fired when this thing happens.'
          type: null
          arguments: [
            name: 'options'
            description: 'options hash'
            type: null
          ]
        ]

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
      expect(doc.sections[1]).toEqual
        type: 'examples'
        examples: [{
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

    it "ignores examples when no examples specified", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        * `something` A {Bool}

        ## Examples
      """
      doc = parse(str)
      expect(doc.sections[1]).not.toBeDefined()
