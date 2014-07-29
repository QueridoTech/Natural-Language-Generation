class NL

  global = null;

  constructor: (x) ->
    @name = 'mac'
    @nums = []
    global = @

  A = ->
    console.log 'A', global.name

  B = ->
    console.log 'B', global.name


  calulate = (opeator) ->
    result = 0
    if opeator is '+'
      global.nums.forEach (num) ->
        result += num
    else if opeator is '-'
      global.nums.forEach (num) ->
        result -= num
    else
      throw new Error "#{opeator} type is not support."

    result


  test: ->
    console.log '`before set name`'
    A()
    @name = 'xxxxx'
    console.log '`after set name`'
    A()

  set: (num) ->
    if typeof num is 'number'
      @nums.push num
    else if num instanceof Array
      # @nums.concat num
      num.forEach (item) =>
        @nums.push item
    @


  get: ->
    @nums


  plus: ->
    calulate '+'


  minus: ->
    calulate '-'



nl = new NL '1'
nl.test()
p = nl.set(10).set([20, 30])
console.log nl.get()
console.log p.plus()
console.log p.minus()
