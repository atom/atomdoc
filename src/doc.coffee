module.exports =
class Doc
  constructor: (@originalText) ->
    @visibility = 'Private'

  isPublic: ->
    /public|essential|extended/i.test(@visibility)

  isInternal: ->
    /internal/i.test(@visibility)

  isPrivate: ->
    not @isPublic() and not @isInternal()

  toJSON: ->
    {
      @visibility
      @summary
      @description
      @arguments
      @examples
      @events
      @delegation
      @returnValues
    }
