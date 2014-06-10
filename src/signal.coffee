class SignalBinding
  constructor: (signal, listener, isOnce, listenerContext, priority) ->
    @_listener = listener
    @_isOnce = isOnce
    @context = listenerContext
    @_signal = signal
    @_priority = priority or 0

  active: true

  params: null

  execute: (paramsArr) ->
    if @active and !!@_listener
      params = if @params then @params.concat paramsArr else paramsArr
      handlerReturn = @_listener.apply @context, params
      if @_isOnce then @detach()
    handlerReturn

  detach: ->
    if @isBound() then @_signal.remove @_listener, @context else null

  isBound: ->
    !!@_signal and !!@_listener

  isOnce: ->
    @_isOnce

  getListener: ->
    @_listener

  getSignal: ->
    @_signal

  _destroy: ->
    delete @_signal
    delete @_listener
    delete @context

  toString: ->
    "[SignalBinding isOnce:#{@_isOnce}, isBound:#{@isBound()}, active:#{@active}]"

module.exports = class Signal
  constructor: ->
    @_bindings = []
    @_prevParams = null
    self = @
    @dispatch = -> Signal::dispatch.apply(self, arguments)

  memorize: false

  _shouldPropagate: true

  active: true

  validateListener: (listener, fnName) ->
    if typeof listener isnt 'function'
      throw Error('listener is a required param of {fn}() and should be a Function.'.replace('{fn}', fnName))

  _registerListener: (listener, isOnce, listenerContext, priority) ->
    prevIndex = @_indexOfListener listener, listenerContext

    if prevIndex isnt -1
      binding = @_bindings[prevIndex]
      if (binding.isOnce() isnt isOnce)
        throw Error("You cannot add#{if isOnce then '' else 'Once'}() then add#{if !isOnce then '' else 'Once'}() the same listener without removing the relationship first.")
    else
      binding = new SignalBinding(@, listener, isOnce, listenerContext, priority)
      @_addBinding binding

    if @memorize and @_prevParams then binding.execute @_prevParams
    binding
  

  _addBinding: (binding) ->
    n = @_bindings.length
    loop
      --n
      break unless @_bindings[n] and binding._priority <= @_bindings[n]._priority
    @_bindings.splice n + 1, 0, binding
    
  _indexOfListener: (listener, context) ->
    n = @_bindings.length
    cur = undefined
    while n--
      cur = @_bindings[n]
      return n  if cur._listener is listener and cur.context is context
    -1

  has: (listener, context) ->
    @_indexOfListener(listener, context) isnt -1
  
  add: (listener, listenerContext, priority) ->
    @validateListener(listener, 'add')
    @_registerListener(listener, false, listenerContext, priority)
  
  addOnce: (listener, listenerContext, priority) ->
    @validateListener(listener, 'addOnce')
    @_registerListener(listener, true, listenerContext, priority)

  remove: (listener, context) ->
    @validateListener listener, "remove"
    i = @_indexOfListener(listener, context)
    if i isnt -1
      @_bindings[i]._destroy() #no reason to a Phaser.SignalBinding exist if it isn't attached to a signal
      @_bindings.splice i, 1
    listener

  removeAll : ->
    n = @_bindings.length
    @_bindings[n]._destroy() while n--
    @_bindings.length = 0
    
  getNumListeners: ->
    @_bindings.length
  
  halt: ->
    @_shouldPropagate = false
  
  
  dispatch : (params) ->
    return  unless @active
    paramsArr = Array::slice.call(arguments)
    n = @_bindings.length
    bindings = undefined
    @_prevParams = paramsArr  if @memorize
    
    return  unless n
    bindings = @_bindings.slice() #clone array in case add/remove items during dispatch
    @_shouldPropagate = true #in case `halt` was called before dispatch or during the previous dispatch.
    
    #execute all callbacks until end of the list or until a callback returns `false` or stops propagation
    #reverse loop since listeners with higher priority will be added at the end of the list
    loop
      n--
      break unless bindings[n] and @_shouldPropagate and bindings[n].execute(paramsArr) isnt false
  
  forget: ->
    @_prevParams = null
  
  dispose: ->
    @removeAll()
    delete @_bindings
    delete @_prevParams
  
  toString: -> "[Signal active: #{@active} numListeners: #{@getNumListeners()} ]"
