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

  setReturnValues: (returnValues) ->
    if @returnValues?
      @returnValues = @returnValues.concat returnValues
    else
      @returnValues = returnValues
