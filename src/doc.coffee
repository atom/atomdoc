module.exports =
class Doc
  constructor: (@originalText) ->
    @visibility = 'Private'
    @sections = []

  isPublic: ->
    /public|essential|extended/i.test(@visibility)

  isInternal: ->
    /internal/i.test(@visibility)

  isPrivate: ->
    not @isPublic() and not @isInternal()

  addSection: (section) ->
    @sections.push section

  toJSON: ->
    {
      @visibility
      @summary
      @description
      @sections
      # @arguments
      # @examples
      # @events
      @delegation
      @returnValues
    }