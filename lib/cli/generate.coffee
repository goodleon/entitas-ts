#!/usr/bin/env coffee
###
 * Entitas code generation
 *
 * emulate the partial class strategy for extensions
 * used by Entitas_CSharp
 *
###
fs = require('fs')
path = require('path')
config = require("#{process.cwd()}/entitas.json")


params = (a, sep = ', ') ->
  b = []
  for item in a
    b.push item.split(':')[0]
  return b.join(sep)

module.exports =
#
# generate entity extensions
#
# @return none
#
  run: () ->


    ts = [] # StringBuilder for generated typescript code
    js = [] # StringBuilder for generated javascript code
    d1 = [] # StringBuilder for associated *.d.ts file: Entity
    d2 = [] # StringBuilder for associated *.d.ts file: Matcher
    d3 = [] # StringBuilder for associated *.d.ts file: Pool
    ex = {} # Extensions
    ###
     * Header
    ###
    ts.push "/**"
    ts.push " * Entitas Generated Classes for #{config.namespace}"
    ts.push " *"
    ts.push " * do not edit this file"
    ts.push " */"
    ts.push "module #{config.namespace} {"
    ts.push ""
    ts.push "  import Pool = entitas.Pool;"
    ts.push "  import Entity = entitas.Entity;"
    ts.push "  import Matcher = entitas.Matcher;"
    ts.push "  import ISystem = entitas.ISystem;"
    ts.push "  import IMatcher = entitas.IMatcher;"
    ts.push "  import IComponent = entitas.IComponent;"

    js.push "/**"
    js.push " * Entitas Generated Extensions for #{config.namespace}"
    js.push " *"
    js.push " * do not edit this file"
    js.push " */"
    js.push "(function(){"
    js.push "  var Pool = entitas.Pool;"
    js.push "  var Matcher = entitas.Matcher;"
    js.push "  var Entity = entitas.Entity;"
    js.push "  var Matcher = entitas.Matcher;"
    for Name, properties of config.components
      js.push "  var #{Name}Component = #{config.namespace}.#{Name}Component;"
    js.push "  var CoreComponentIds = #{config.namespace}.CoreComponentIds;"
    ###
     * Components Enum
    ###
    ts.push ""
    ts.push "  export enum CoreComponentIds {"
    for Name, properties of config.components
      ts.push "    #{Name},"
    ts.push "    TotalComponents"
    ts.push "  }"
    ts.push ""

    ###
     * Components Class Definitions
    ###
    ts.push ""
    for Name, properties of config.components
      ts.push "  export class #{Name}Component implements IComponent {"
      for p in properties
        ts.push "    public #{p};"
      ts.push "  }"
    ts.push ""

    ###
     * Extend Entity with components
    ###
    ts.push ""
    for Name, properties of config.components
      name = Name[0].toLowerCase()+Name[1...];
      switch properties
        when false
          js.push "  Entity.#{name}Component = new #{Name}Component();"
          js.push "  Object.defineProperty(Entity.prototype, 'is#{Name}', {"
          js.push "    get: function() {"
          js.push "      return this.hasComponent(CoreComponentIds.#{Name});"
          js.push "    },"
          js.push "    set: function(value) {"
          js.push "      if (value !== this.is#{Name}) {"
          js.push "        if (value) {"
          js.push "          this.addComponent(CoreComponentIds.#{Name}, Entity.#{name}Component);"
          js.push "        } else {"
          js.push "          this.removeComponent(CoreComponentIds.#{Name});"
          js.push "        }"
          js.push "      }"
          js.push "    }"
          js.push "  });"
          js.push "  Entity.prototype.set#{Name} = function(value) {"
          js.push "    this.is#{Name} = value;"
          js.push "    return this;"
          js.push "  };"

          d1.push "        static #{name}Component: any;"
          d1.push "        is#{Name}: boolean;"
          d1.push "        set#{Name}(value: boolean);"

        else
          js.push "  Entity._#{name}ComponentPool = [];"
          js.push "  Entity.clear#{Name}ComponentPool = function() {"
          js.push "    Entity._#{name}ComponentPool.length = 0;"
          js.push "  };"
          js.push "  Object.defineProperty(Entity.prototype, '#{name}', {"
          js.push "    get: function() {"
          js.push "      return this.getComponent(CoreComponentIds.#{Name});"
          js.push "    }"
          js.push "  });"
          js.push "  Object.defineProperty(Entity.prototype, 'has#{Name}', {"
          js.push "    get: function() {"
          js.push "      return this.hasComponent(CoreComponentIds.#{Name});"
          js.push "    }"
          js.push "  });"
          js.push "  Entity.prototype.add#{Name} = function(#{params(properties)}) {"
          js.push "    var component = Entity._#{name}ComponentPool.length > 0 ? Entity._#{name}ComponentPool.pop() : new #{Name}Component();"
          for p in properties
            js.push "    component.#{p.split(':')[0]} = #{p.split(':')[0]};"
          js.push "    return this.addComponent(CoreComponentIds.#{Name}, component);"

          js.push "  };"
          js.push "  Entity.prototype.replace#{Name} = function(#{params(properties)}) {"
          js.push "    var previousComponent = this.has#{Name} ? this.#{name} : null;"
          js.push "    var component = Entity._#{name}ComponentPool.length > 0 ? Entity._#{name}ComponentPool.pop() : new #{Name}Component();"
          for p in properties
            js.push "    component.#{p.split(':')[0]} = #{p.split(':')[0]};"
          js.push "    this.replaceComponent(CoreComponentIds.#{Name}, component);"
          js.push "    if (previousComponent != null) {"
          js.push "      Entity._#{name}ComponentPool.push(previousComponent);"
          js.push "    }"
          js.push "    return this;"
          js.push "  };"
          js.push "  Entity.prototype.remove#{Name} = function() {"
          js.push "    var component = this.#{name};"
          js.push "    this.removeComponent(CoreComponentIds.#{Name});"
          js.push "    Entity._#{name}ComponentPool.push(component);"
          js.push "    return this;"
          js.push "  };"

          d1.push "        static _#{name}ComponentPool;"
          d1.push "        static clear#{Name}ComponentPool();"
          d1.push "        #{name}: any;"
          d1.push "        has#{Name}: boolean;"
          d1.push "        add#{Name}(#{properties.join(', ')});"
          d1.push "        replace#{Name}(#{properties.join(', ')});"
          d1.push "        remove#{Name}();"


    ###
     * Matchers
    ###
    for Name, properties of config.components
      name = Name[0].toLowerCase()+Name[1...];
      js.push "  Matcher._matcher#{Name}=null;"
      js.push "  "
      js.push "  Object.defineProperty(Matcher, '#{Name}', {"
      js.push "    get: function() {"
      js.push "      if (Matcher._matcher#{Name} == null) {"
      js.push "        Matcher._matcher#{Name} = Matcher.allOf(CoreComponentIds.#{Name});"
      js.push "      }"
      js.push "      "
      js.push "      return Matcher._matcher#{Name};"
      js.push "    }"
      js.push "  });"

      d2.push "        static _matcher#{Name};"
      d2.push "        static #{Name}: Matcher;"

    ###
     * Pooled Entities
    ###
    for Name, pooled of config.entities
      if pooled
        name = Name[0].toLowerCase()+Name[1...];
        properties = config.components[Name]
        if config.components[Name] is false
          js.push "  Object.defineProperty(Pool.prototype, '#{name}Entity', {"
          js.push "    get: function() {"
          js.push "      return this.getGroup(Matcher.#{Name}).getSingleEntity();"
          js.push "    }"
          js.push "  });"
          js.push "  Object.defineProperty(Pool.prototype, 'is#{Name}', {"
          js.push "    get: function() {"
          js.push "      return this.#{name}Entity != null;"
          js.push "    },"
          js.push "    set: function(value) {"
          js.push "      var entity = this.#{name}Entity;"
          js.push "      if (value != (entity != null)) {"
          js.push "        if (value) {"
          js.push "          this.createEntity().is#{Name} = true;"
          js.push "        } else {"
          js.push "          this.destroyEntity(entity);"
          js.push "        }"
          js.push "      }"
          js.push "    }"
          js.push "  });"

          d3.push "        #{name}Entity: Entity;"
          d3.push "        is#{Name}: boolean;"

        else
          js.push "  Object.defineProperty(Pool.prototype, '#{name}Entity', {"
          js.push "    get: function() {"
          js.push "      return this.getGroup(Matcher.#{Name}).getSingleEntity();"
          js.push "    }"
          js.push "  });"
          js.push "  Object.defineProperty(Pool.prototype, '#{name}', {"
          js.push "    get: function() {"
          js.push "      return this.#{name}Entity.#{name};"
          js.push "    }"
          js.push "  });"
          js.push "  Object.defineProperty(Pool.prototype, 'has#{Name}', {"
          js.push "    get: function() {"
          js.push "      return this.#{name}Entity != undefined;"
          js.push "    }"
          js.push "  });"
          js.push "  Pool.prototype.set#{Name} = function(#{params(properties)}) {"
          js.push "    if (this.has#{Name}) {"
          js.push "      throw new SingleEntityException(Matcher.#{Name});"
          js.push "    }"
          js.push "    var entity = this.createEntity();"
          js.push "    entity.add#{Name}(#{params(properties)});"
          js.push "    return entity;"
          js.push "  };"
          js.push "  Pool.prototype.replace#{Name} = function(#{params(properties)}) {"
          js.push "    var entity = this.#{name}Entity;"
          js.push "    if (entity == null) {"
          js.push "      entity = this.set#{Name}(#{params(properties)});"
          js.push "    } else {"
          js.push "      entity.replace#{Name}(#{params(properties)});"
          js.push "    }"
          js.push "    return entity;"
          js.push "  };"
          js.push "  Pool.prototype.remove#{Name} = function() {"
          js.push "    this.destroyEntity(#{name}Entity);"
          js.push "  };"

          d3.push "        #{name}Entity: Entity;"
          d3.push "        #{name}: IComponent;"
          d3.push "        has#{Name}: boolean;"
          d3.push "        set#{Name}(#{properties.join(', ')}): Entity;"
          d3.push "        replace#{Name}(#{properties.join(', ')}): Entity;"
          d3.push "        remove#{Name}(): void;"


    ###
     * Pools
    ###
    ts.push "  export class Pools {"
    ts.push "    "
    ts.push "    static _allPools:Array<Pool>;"
    ts.push "    "
    ts.push "    static get allPools():Array<Pool> {"
    ts.push "      if (Pools._allPools == null) {"
    ts.push "        Pools._allPools = [Pools.core];"
    ts.push "      }"
    ts.push "      return Pools._allPools;"
    ts.push "    }"
    ts.push "    "
    ts.push "    static _core:Pool;"
    ts.push "    "
    ts.push "    static get core():Pool {"
    ts.push "      if (Pools._core == null) {"
    ts.push "        Pools._core = new Pool(CoreComponentIds, CoreComponentIds.TotalComponents);"
    ts.push "      }"
    ts.push "    "
    ts.push "      return Pools._core;"
    ts.push "    }"
    ts.push "  }"
    for Name of config.extensions
      ts.push "  #{config.namespace}.extensions.#{Name}.extend();"
    ts.push "}"

    js.push "})();"

    fs.writeFileSync(path.join(process.cwd(), config.src, config.output.typescript), ts.join('\n'))
    fs.writeFileSync(path.join(process.cwd(), config.src, config.output.javascript), js.join('\n'))

    for Name, klass of config.extensions
      ex[Name] = [] # StringBuilder for this extension
      for method, args of klass
        [name, type] = method.split(':');
        ex[Name].push "        #{name}(#{args.join(', ')}):#{type};"

    def = (dts, className, dd) ->
      i = dts.indexOf(className)+className.length
      dts = dts.substr(0, i) + '\n' + dd.join('\n') + dts.substr(i);
      return dts


    dts = fs.readFileSync(path.join(__dirname, 'entitas.d.ts'), 'utf8')
    dts = def(dts, '    class Entity {', d1)
    dts = def(dts, '    class Matcher implements IAllOfMatcher, IAnyOfMatcher, INoneOfMatcher {', d2)
    dts = def(dts, '    class Pool {', d3)
    for Name, d0 of ex
      dts = def(dts, "    class #{Name} {", d0)

    fs.writeFileSync(path.join(process.cwd(), config.src, config.output.declaration), dts)
