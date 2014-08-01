{parse} = require '../src/parser'

describe "parser", ->
  describe "basic parsing", ->
    it "parses a simple one liner", ->
      str = "Public: Batch multiple operations as a single undo/redo step."
      doc = parse(str)

      expect(doc.summary).toBe 'Batch multiple operations as a single undo/redo step.'
      expect(doc.description).toBe 'Batch multiple operations as a single undo/redo step.'
      expect(doc.visibility).toBe 'Public'
      expect(doc.arguments).not.toBeDefined()
      expect(doc.returnValue).not.toBeDefined()
      expect(doc.examples).not.toBeDefined()
      expect(doc.delegation).not.toBeDefined()

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
