Signal = require './signal'
Dictionary = require './dictionary'

module.exports.Component = class Component

module.exports.Prefab = class Prefab

module.exports.Entity = class Entity
    constructor: ->
        @componentAdded = new Signal()
        @componentRemoved = new Signal()
        @id = Math.floor((1 + Math.random()) * 0xffffff)
            .toString(16).substring(1)
        @_components = new Dictionary()
    add: (component) ->
        @_components.add component.constructor.name, component
        @componentAdded.dispatch component, @
    remove: (component) ->
        @_components.remove @_getCompClassName component
        @componentRemoved.dispatch component, @
    get: (component) ->
        @_components.retrieve @_getCompClassName component
    has: (component) ->
        @_components.has @_getCompClassName component
    toArray: ->
        @_components.toArray()
    _getCompClassName: (component)->
        return (if component.constructor.name is 'Function'
        then component.name
        else component.constructor.name)


module.exports.System = class System
    constructor: ->
        @requiredComponents = []
        @validEntities = []
    wants: (e) ->
        e = e.toArray()
        (e.some((ec) -> (ec.constructor == c)) for c in @requiredComponents)
          .reduce (t, s) -> t and s
    contains: (e) ->
        @validEntities.indexOf(e) isnt -1
    addEntity: (e) ->
        @validEntities.push(e)
    removeEntity: (e) ->
        @validEntities.splice @validEntities.indexOf e, 1

module.exports.CESEngine = class ComponentEntitySystemEngine
    constructor: ->
        @entities = []
        @systems = []
    instantiate: (klass, args...) ->
        entity = new Entity()
        @addEntity entity
        prefab = new klass entity, args...
    addEntity: (entity)->
        entity.componentAdded.add @onComponentAdded
        entity.componentRemoved.add @onComponentRemoved
        @entities.push entity
        entity
    removeEntity: (entity)->
        entity.componentAdded.remove @onComponentAdded
        entity.componentRemoved.remove @onComponentRemoved
        @entities.splice @entities.indexOf entity, 1
    onComponentAdded: (component, entity) =>
        for s in @systems when (not s.contains entity) and (s.wants entity)
            s.addEntity entity
        return
    onComponentRemoved: (component, entity) =>
        for s in @systems when (s.contains entity) and (not s.wants entity)
            s.removeEntity entity
        return
    addSystem: (system) ->
        @systems.push system
        system
    removeSystem: (system) ->
        @systems.splice @systems.indexOf system, 1





