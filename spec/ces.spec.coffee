{Component, Entity, System, CESEngine, Prefab} = require '../src/ces'
Signal = require '../src/signal'

describe 'Prefabs',->
    engine = null
    beforeEach ->
        engine = new CESEngine()
    it 'exists',->
        class TransformationComponent
            constructor: (@x, @y, @rotation)->
                
        class ActorPrefab extends Prefab
            blup: ->
                console.log 'yessir'
            constructor: (@entity, transform)->
                @_transform = new TransformationComponent(
                    transform.x,
                    transform.y,
                    transform.rotation)
                
        actor = engine.instantiate(ActorPrefab, {x:42, y:32, rotation:0})
        expect(actor).toBeTruthy()
        expect(actor._transform.x).toBe 42

describe 'Component Entity System', ->
  engine = null
  beforeEach ->
    engine = new CESEngine()
  it 'Has stuff', ->
    expect(engine).toBeTruthy()
    expect(Component).toBeTruthy()
    expect(Entity).toBeTruthy()
    expect(System).toBeTruthy()
    expect(CESEngine).toBeTruthy()

  it 'adds/removes systems and entities to Engine', ->
    
    class CrazyComponent extends Component

    class CrazySystem extends System
      constructor: ->
        super()
        @requiredComponents = [CrazyComponent]

    testSystem = new CrazySystem()
    engine.addSystem testSystem
    expect(engine.systems.length).toBe 1
    engine.removeSystem testSystem
    expect(engine.systems.length).toBe 0

    testEntity = new Entity()
    engine.addEntity testEntity
    expect(engine.entities.length).toBe 1
    engine.removeEntity testEntity
    expect(engine.entities.length).toBe 0

        
  it 'adds entities to Systems when valid', ->
    
    class CrazyComponent extends Component
    class CrazyComponent2 extends Component

    class CrazySystem extends System
      constructor: ->
        super()
        @requiredComponents = [CrazyComponent]

    testSystem = new CrazySystem()
    engine.addSystem testSystem
    
    entity1 = new Entity()
    engine.addEntity entity1
    
    entity1.add new CrazyComponent()
    expect(entity1.get(CrazyComponent)).toBeTruthy()
    expect(testSystem.contains entity1).toBeTruthy()
    entity1.remove CrazyComponent
    expect(entity1.get(CrazyComponent)).toBeFalsy()
    expect(testSystem.contains entity1).toBeFalsy()
    entity1.add new CrazyComponent2()
    expect(testSystem.contains entity1).toBeFalsy()
    entity1.add new CrazyComponent()
    expect(entity1.get(CrazyComponent)).toBeTruthy()

  it 'handles system 2 system communication with Signals', ->
    class SoundComponent extends Component
    class HealthComponent extends Component
      constructor: ->
        @health = 100
      heal: (amount) ->
        @health += amount
      hurt: (amount) ->
        @health -= amount
        
    class HealthSystem extends System
      constructor: ->
        super()
        @died = new Signal()
        @requiredComponents = [HealthComponent]
      heal: (entity, amount) ->
        entity.get(HealthComponent).heal amount
      hurt: (entity, amount) ->
        entity.get(HealthComponent).hurt amount
        if entity.get(HealthComponent).health <= 0
          @died.dispatch entity, @
      
    class SoundSystem extends System
      constructor: ->
        super()
        @requiredComponents = [SoundComponent]
      on:
        died: (entity)-> #console.log 'play sound'
    
    health = new HealthSystem()
    engine.addSystem health
    sound = new SoundSystem()
    engine.addSystem sound
    health.died.add sound.on.died
    
    entity1 = new Entity()
    engine.addEntity entity1
    entity1.add new HealthComponent()
    expect(entity1.get(HealthComponent).health).toBe 100
    health.heal(entity1, 50)
    expect(entity1.get(HealthComponent).health).toBe 150
    health.hurt(entity1, 200)
    spyOn(sound.on, 'died')
    expect(entity1.get(HealthComponent).health).toBe -50
    setTimeout ->
      expect(sound.on.died).toHaveBeenCalled()
    , 1

    


  
