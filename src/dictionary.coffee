###
Dictionary

@author Brett Jephson
###


class Dictionary
    keys: null
    values: null
    constructor: ->
        @keys = []
        @values = []
        this
            
    add: (key, value) ->
        keyIndex = @getIndex(key)
        if keyIndex >= 0
            @values[keyIndex] = value
        else
            @keys.push key
            @values.push value

    remove: (key) ->
        keyIndex = @getIndex(key)
        if keyIndex >= 0
            @keys.splice keyIndex, 1
            @values.splice keyIndex, 1
        else
            throw Error("Key does not exist")

    retrieve: (key) ->
        value = null
        keyIndex = @getIndex(key)
        value = @values[keyIndex]  if keyIndex >= 0
        value

    getIndex: (testKey) ->
        i = 0
        len = @keys.length
        key = undefined
        while i < len
            key = @keys[i]
            return i  if key is testKey
            ++i
        -1

    has: (testKey) ->
        i = 0
        len = @keys.length
        key = undefined
        while i < len
            key = @keys[i]
            return true  if key is testKey
            ++i
        false

    forEach: (action) ->
        i = 0
        len = @keys.length
        key = undefined
        value = undefined
        while i < len
            key = @keys[i]
            value = @values[i]
            breakHere = action(key, value)
            return false  if breakHere is "return"
            ++i
        true

    toArray: ->
        @values

module.exports = Dictionary

