###*
 * Natural Language base class
 * ------------------------------------------------------------
 * @name NaturalLanguage
 * 
 * @constructor
 * @param {Array} data - a list of inputs
###
exports.NaturalLanguage = 
class NaturalLanguage

  ###*
   * ------------------------------------------------------------
   * Prepare resource
   * ------------------------------------------------------------
  ###
  global    = null
  _         = require "underscore"
  config    = require "./../resources/config.json"
  sentences = require "./../resources/sentences.json"

  constructor: (data) ->
    @data           = data
    @dataConfig     = {}
    @sentenceConfig = {}
    @random         = true
    global          = @

  ###*
   * ------------------------------------------------------------
   * HELPER FUNCTION
   * ------------------------------------------------------------
  ###


  ###*
   * Change the first character of the string to capital
   * ------------------------------------------------------------
   * @name capitalize
   * @param  {string} data
   * @return {string} capitalized string
  ###

  capitalize = (data) ->
    data.charAt(0).toUpperCase() + data.slice 1


  ###*
   * Replace sentence pattern with string in data object
   * (single sentence, no capitalization or full stop)
   * ------------------------------------------------------------
   * @name replaceStr
   * @param  {array}  patterns - array of sentences
   * @param  {object} data - displayInfo object
   * @return {string} final sentence
  ###

  replaceStr = (patterns, data) ->
    if global.random
      pattern = _.sample patterns
    else
      pattern = patterns[0]
    _.each data, (item, key) ->
      pattern = pattern.replace "{#{key}}", item
    pattern


  ###*
   * Replace sentence pattern with string in data object
   * (combined sentence, with capitalization and full stop)
   * ------------------------------------------------------------
   * @name replaceCombinedStr
   * @param  {array}  patterns - array of sentences
   * @param  {array}  data - array of displayInfo object
   * @return {string} final sentence
  ###

  replaceCombinedStr = (patterns, data) ->
    if global.random
      pattern = _.sample patterns
    else
      pattern = patterns[0]
    _.each data, (items, i) ->
      _.each items, (item, key) ->
        pattern = pattern.replace "{#{key}.#{i}}", items[key]
    pattern


  ###*
   * ------------------------------------------------------------
   * METHOD LIST
   * ------------------------------------------------------------
  ###


  ###*
   * Add more required attributes
   * ------------------------------------------------------------
   * @name setAttrs
   * @param  {array}  data - array of inputs
   * @return {Object} new data with more attributes
   * @private
  ###

  setAttrs = (data) ->
    _.each data, (item, i) ->
      if item.options isnt undefined
        # item.options = _.extend _.clone(config.default), item.options
        item.options = _.defaults(item.options, config.default);
      else
        item.options = {
          "priority": {
            "init": 1,
            "negativeFactor": 20,
            "positiveFactor": 100
          },
          "level": {
            "threshold": 0.09,
            "sensitiveness": 1
          }
        }
      item.dataType     = "default" unless item.dataType

      # Custom for more attributes
      if global.dataConfig[item.dataType] and global.dataConfig[item.dataType].setAttrs
        item = global.dataConfig[item.dataType].setAttrs item

      # Default attributes
      item.alwaysShow   = false if typeof item.alwaysShow is "undefined"
      item.contentGroup = "default" unless item.contentGroup
      item.sentenceType = "default" unless item.sentenceType
      item.precision    = 0 unless item.precision != "undefined"
      item.difference   = getDifference item
      item.displayInfo  = getDisplayInfo item
      item.priority     = calculatePriority item
      item.level        = calculateLevel item
      item.levelType    = calculateType item.level

    data


  ###*
   * Get the difference between old value and current value
   * ------------------------------------------------------------
   * @name getDifference
   * @param  {object}        data
   * @return {number/string} difference value or 'na' if there is no oldData
   * @private
  ###

  getDifference = (data) ->
    # Override
    if global.dataConfig[data.dataType] and global.dataConfig[data.dataType].getDifference
      return global.dataConfig[data.dataType].getDifference data

    # Default
    if typeof data.oldData isnt "undefined" and typeof data.oldData == "number"
      data.newData - data.oldData
    else 
      "na"


  ###*
   * Prepare strings required to show in the sentence
   * ------------------------------------------------------------
   * @name getDisplayInfo
   * @param  {object} data
   * @return {object} information required to display in the sentence
   * @private
  ###

  getDisplayInfo = (data) ->
    # Override
    if global.dataConfig[data.dataType] and global.dataConfig[data.dataType].getDisplayInfo
      return global.dataConfig[data.dataType].getDisplayInfo data

    # Default
    result = {}
    result.title = data.title.toLowerCase()
    
    if typeof data.oldData isnt "undefined"
      if typeof data.oldData == "number"
        result.oldData    = data.oldData.toFixed data.precision
      else
        result.oldData = data.oldData.toLowerCase()
      if typeof data.difference == "number"
        result.difference = Math.abs(data.difference).toFixed data.precision
    if typeof data.newData == "number"
      result.newData = data.newData.toFixed(data.precision)
    else
      result.newData = data.newData.toLowerCase()
    
    result


  ###*
   * Calculate the priority of change
   * ------------------------------------------------------------
   * @name calculatePriority
   * @param  {object} data
   * @return {number} new priority
   * @private
  ###

  calculatePriority = (data) ->
    # Override
    if global.dataConfig[data.dataType] and global.dataConfig[data.dataType].calculatePriority
      return global.dataConfig[data.dataType].calculatePriority data

    # Default
    priorityConfig = data.options.priority

    if data.difference is "na"
      return priorityConfig.init
    else if data.difference > 0
      newPriority = priorityConfig.init +
                    (priorityConfig.positiveFactor * data.difference)
    else
      newPriority = priorityConfig.init +
                    (priorityConfig.negativeFactor * Math.abs(data.difference))

    parseInt newPriority.toFixed(0), 10


  ###*
   * Calculate the intesity of change
   * ------------------------------------------------------------
   * @name calculateLevel
   * @param  {object} data
   * @return {number} intensity of the change
   * @private
  ###

  calculateLevel = (data) ->
    # Override
    if global.dataConfig[data.dataType] and global.dataConfig[data.dataType].calculateLevel
      return global.dataConfig[data.dataType]
             .calculateLevel data.difference, data.options.level

    # Default
    levelConfig = data.options.level

    if data.difference is "na"
      level = "na"
    else
      absoluteDifference = Math.abs data.difference
      if absoluteDifference < levelConfig.threshold
        level = 0
      else
        level = Math.ceil data.difference / levelConfig.sensitiveness
        level = 3 if level > 3
        level = -3 if level < -3
    level


  ###*
   * Calculate the type of intesity
   * ------------------------------------------------------------
   * @name calculateType
   * @param  {number} level
   * @return {string} levelType
   * @private
  ###

  calculateType = (level) ->
    if level > 0
      "positive"
    else if level < 0
      "negative"
    else if level is "na"
      "na"
    else
      "neutral"


  ###*
   * Select number of data to display and sort by priority
   * ------------------------------------------------------------
   * @name selectData
   * @param  {array}  data - array of data split into two groups: alwaysShow and sortedData
   * @param  {number} nData - number of data to show
   * @return {array}  selected, sorted data by priority
   * @private
  ###

  selectData = (data, nData) ->
    groupedData = groupData data
    result = groupedData.alwaysShow
    if(nData == -1)
      return result.concat groupedData.sortedData
    if result.length < nData
      nRemaining = nData - result.length
      result = result.concat groupedData.sortedData.slice( 0, nRemaining )
    result.sort (a, b) ->
      b.priority - a.priority

    result


  ###*
   * Group data by alwaysShow attr and sort the group by priority
   * ------------------------------------------------------------
   * @name groupData
   * @param  {array} data - array of data
   * @return {array} data split into two groups, alwaysShow and sortedData
   * @private
  ###

  groupData = (data) ->
    # Remove hidden items
    data = _.filter data, (item) ->
      ! item.hidden

    data = _.groupBy data, "alwaysShow"
    data.sortedData = []
    data.alwaysShow = []

    if data[false]
      data[false].sort (a, b) ->
        b.priority - a.priority
      data.sortedData = data[false]
    data.alwaysShow = data[true] if data[true]

    data


  ###*
   * Get a valid list of sentences for random selecting
   * ------------------------------------------------------------
   * @name getSimpleSentenceList
   * @param  {object} data - data object
   * @param  {array}  simpleSentences - sentences from all types
   * @return {array}  array of valid sentences
   * @private
  ###

  getSimpleSentenceList = (data, simpleSentencese) ->

    # Override
    if global.sentenceConfig[data.sentenceType] \
      and global.sentenceConfig[data.sentenceType].getSimpleSentenceList
        return global.sentenceConfig[data.sentenceType]
               .getSimpleSentenceList data, simpleSentencese

    # Default
    if typeof data.oldData is "undefined" # No oldData
      if typeof sentences.simpleSentences[data.sentenceType] isnt "undefined" \
        and typeof sentences.simpleSentences[data.sentenceType]["na"] isnt "undefined"
          sentences.simpleSentences[data.sentenceType]["na"]
      else
        sentences.simpleSentences["default"]["na"]
    else
      if typeof sentences.simpleSentences[data.sentenceType] isnt "undefined" \
        and typeof sentences.simpleSentences[data.sentenceType][data.levelType] isnt "undefined"
          if typeof sentences.simpleSentences[data.sentenceType][data.levelType][data.level.toString()] isnt "undefined"
            sentences.simpleSentences[ data.sentenceType ][ data.levelType ][ data.level.toString() ]
          else
            sentences.simpleSentences[ data.sentenceType ][ data.levelType ]
      else
        sentences.simpleSentences["default"][ data.levelType ][ data.level.toString() ]


  ###*
   * Group data into contentGroups and loop through each
   * contentGroup to create sentence(s)
   * ------------------------------------------------------------
   * @name buildSimpleSentence
   * @param  {object} data - data object
   * @return {array}  array of sentences
   * @private
  ###

  buildSimpleSentence = (data) ->
    simpleSentences = getSimpleSentenceList data, sentences.simpleSentences
    replaceStr simpleSentences, data.displayInfo


  ###*
   * Add simple sentence into the data object
   * ------------------------------------------------------------
   * @name addSimpleSentence
   * @param  {array} array of data to generate simple sentences
   * @return {array} array of data with sentence attribute inserted
   * @private
  ###

  addSimpleSentence = (data) ->
    for i of data
      data[i].displayInfo.sentence = buildSimpleSentence(data[i])
    data

  ###*
  * Get a valid list of compound sentences
  * ------------------------------------------------------------
  * @name getCompoundSentenceList
  * @param  {object} data - data object
  * @param  {array}  compoundSentences - sentences from all types
  * @return {array}  array of valid sentences
  * @private
  ###

  getCompoundSentenceList = (data, compoundSentences) ->
    # Override
    if(global.sentenceConfig[data.sentenceType] && global.sentenceConfig[data.sentenceType].getCompoundSentenceList)
      return global.sentenceConfig[data.sentenceType].getCompoundSentenceList(data, compoundSentences)
    # Default
    if sentences.compoundSentences[data.sentenceType] isnt undefined
      compoundSentences[data[0].sentenceType]
    else
      compoundSentences.default

  ###*
   * Combine two simple sentencese that are in the same sentenceGroup
   * ------------------------------------------------------------
   * @name buildCompoundSentence
   * @param  {array}  array of one or two data objects to combine
   * @return {string} a combine sentence
   * @private
  ###

  buildCompoundSentence = (data) ->
    types = _.pluck data, "levelType"
    type = types.join "_"

    moreDisplayInfo = _.pluck addSimpleSentence(data), "displayInfo"
    compoundSentences = getCompoundSentenceList data, sentences.compoundSentences
    selectedSentences = _.find compoundSentences, (group) ->
      _.contains(group.type, type);
    capitalize replaceCombinedStr( selectedSentences.sentences, moreDisplayInfo )


  ###*
   * Group data into contentGroups and loop through each
   * contentGroup to create sentence(s)
   * ------------------------------------------------------------
   * @name buildSentences
   * @param  {array} data - array sorted by priority but not grouped
   * @return {array} array of sentences
   * @private
  ###

  buildSentences = (data) ->
    result = []
    data = _.groupBy data, "contentGroup"

    # for group of data
    _.each data, (group) ->
      if group.length > 2
        i = 0
        while i < group.length
          if i + 1 is group.length
            result.push buildCompoundSentence [ group[i] ]
          else
            result.push buildCompoundSentence [ group[i], group[parseInt(i)+1] ]
          i = i + 2
      else
        result.push buildCompoundSentence group

    result

  addType: (title, func = {}) ->
    if @dataConfig[title]
      @dataConfig[title] = _.extend(@dataConfig[title], func)
    else 
      @dataConfig[title] = func

  addSentence: (title, func = null) ->
    if @sentenceConfig[title]
      @sentenceConfig[title] = _.extend(@sentenceConfig[title], func)
    else 
      @sentenceConfig[title] = func

  ###*
   * Generate sentences from a list of data
   * ------------------------------------------------------------
   * @name NaturalLanguage.generate
   * @param {number} nData - number of sentences to generate
   * @return {String/Number/Object/Function/Boolean} desc
   * @public
  ###
  generate: (nData = -1, random = true) ->
    @random = random
    data = setAttrs @data
    data = selectData data, nData
    result = buildSentences data
    # return data
    # for i of data
    #   console.log data[i].title, ": ", data[i].priority
    return result.join " "

  debug: (nData = -1, random = true) ->
    @random = random
    return setAttrs @data
    data = setAttrs @data
    data = selectData data, nData
    result = buildSentences data

# signType = {
#   words: {
#     "Debt Level": {
#       "-": "0",
#       "Low .*": "+1",
#       "No .*": "+2",
#       "High .* in the past 5 years": "-1",
#       "High .*": "-2",
#       "Very High .*": "-3"
#     },
#     "Share Repurchase": {
#       "-": "0",
#       "Every year": "+2"
#     },
#     "CapEx": {
#       "-": "0",
#       "Very Low": "+2",
#       "Very High": "-2"
#     }
#   },
#   setAttrs: (data) ->
#     data.newScore = @getScore(data.title, data.newData)
#     if(typeof data.oldData != "undefined")
#       data.oldScore = @getScore(data.title, data.oldData)
#     if(data.newScore == '0')
#       data.hidden = true
#     data

#   getDisplayInfo: (data) ->
#     precision = data.precision
#     result = {}
#     result.title = data.title.toLowerCase()
#     result.title = "CapEx" if data.title == "CapEx"
#     result.newData = data.newData.toLowerCase()
#     if(typeof data.oldData != "undefined")
#       result.oldData = data.oldData.toLowerCase()
#     result

#   getScore: (title, data) ->
#     for item of @words[title]
#       pattern = new RegExp(item, "g");
#       if pattern.test(data)
#         return @words[title][item]
#     return null

#   getDifference: (data) ->
#     if(typeof data.oldData != "undefined")
#       parseInt(data.newScore) - parseInt(data.oldScore)
#     else
#       "na"  
# }
# # String with custom functions


# NL = new NaturalLanguage [{
#   "title": "Share Repurchase",
#   "oldData": "-",
#   "newData": "Every year",
#   "dataType": "sign"
# }]
# NL.addType "sign", signType
# # String with custom functions + oldData
# console.log NL.generate(-1, false)

  # adef = {
  #   'key1': 'value1',
  #   'key2': 'value2'
  # }
  # aover ={
  #   'key1': 'value1override',
  #   'key3': 'value3'
  # }
  # console.log _.extend(adef, aover)
  # console.log adef
  # console.log aover