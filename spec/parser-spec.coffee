{parse} = require '../src/parser'

describe "parser", ->
  describe "basic parsing", ->
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

    xit "parses large doc string with multiple arguments and a return value", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        Any group of operations that are logically grouped from the perspective of
        undoing and redoing should be performed in a transaction. If you want to
        abort the transaction, call {::abortTransaction} to terminate the function's
        execution and revert any changes performed up to the abortion.

        fn - A {Function} to call inside the transaction.

        Returns a {Bool}
        Returns null when no function defined
      """
      doc = parse(str)

      expect(doc.summary).toBe 'Batch multiple operations as a single undo/redo step.'
      expect(doc.status).toBe 'Public'
      expect(doc.examples).not.toBeDefined()
      expect(doc.delegation).not.toBeDefined()

      expect(doc.arguments).toEqual [
        name: 'fn'
        description: 'A {Function} to call inside the transaction.'
        type: 'Function'
      ]
      expect(doc.returnValue).toEqual [{
        type: 'Bool'
        description: 'Returns a {Bool}'
      },{
        type: null
        description: 'Returns null when no function defined'
      }]

      expect(doc.description).toBe """
        Batch multiple operations as a single undo/redo step.

        Any group of operations that are logically grouped from the perspective of
        undoing and redoing should be performed in a transaction. If you want to
        abort the transaction, call {::abortTransaction} to terminate the function's
        execution and revert any changes performed up to the abortion.
      """

    xit "parses doc string with examples", ->
      str = """
        Public: Batch multiple operations as a single undo/redo step.

        fn - A {Function} to call inside the transaction.

        Examples

          someFunction (options) ->
            console.log('do stuff', options)
          # => true

          someFunction()
          # => null

        Returns a {Bool}
        Returns null when no function defined
      """
      doc = parse(str)

      expect(doc.summary).toBe 'Batch multiple operations as a single undo/redo step.'
      expect(doc.status).toBe 'Public'
      expect(doc.examples).toEqual ["""
        someFunction (options) ->
          console.log('do stuff', options)
        # => true
      """, """
        someFunction()
        # => null
      """]

      expect(doc.arguments).toEqual [
        name: 'fn'
        description: 'A {Function} to call inside the transaction.'
        type: 'Function'
      ]
      expect(doc.returnValue).toEqual [{
        type: 'Bool'
        description: 'Returns a {Bool}'
      },{
        type: null
        description: 'Returns null when no function defined'
      }]

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
