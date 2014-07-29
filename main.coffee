###*
 * ------------------------------------------------------------
 * Prepare resource
 * ------------------------------------------------------------
###
_              = require 'underscore'
dataConfig     = require './data_config.coffee'
sentenceConfig = require './sentence_config.coffee'
config         = require './resources/config.json'
sentences      = require './resources/sentences.json'
input          = require './resources/input.json'


###*
 * Natural Language base class
 * ------------------------------------------------------------
 * @name NaturalLanguage
 * 
 * @constructor
 * @param {Array} data - a list of inputs
###

class NaturalLanguage

  constructor: (data) ->
    @data = data


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
    pattern = _.sample patterns
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
    pattern = _.sample patterns
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
   * @name getAttrs
   * @param  {array}  data - array of inputs
   * @return {Object} new data with more attributes
   * @private
  ###

  getAttrs = (data) ->

    _.each data, (item, i) ->

      if config[item.title]
        name = item.title
      else
        name = 'default'

      dataType = config[name].dataType

      # Custom for more attributes

      if dataConfig[dataType] and dataConfig[dataType].getAttrs
        console.log "Override #{data.title} for getAttrs"
        item = dataConfig[dataType].getAttrs item

      # Default attributes
      item.dataType     = dataType
      item.difference   = getDifference item
      item.sentenceType = config[name].sentenceType
      item.contentGroup = config[name].contentGroup
      item.displayInfo  = getDisplayInfo item, config[name]
      item.priority     = calculatePriority item, config[name]
      item.level        = calculateLevel item, config[name]
      item.levelType    = calculateType item.level
    data


  ###*
   * Get the difference between old value and current value
   * ------------------------------------------------------------
   * @name getDifference
   * @param  {object}        data
   * @return {number/string} difference value
   * @private
  ###

  getDifference = (data) ->
    # Override
    if dataConfig[data.dataType] and dataConfig[data.dataType].getDifference
      console.log "Override #{data.title} for getDifference"
      return dataConfig[data.dataType].getDifference data

    # Default
    if typeof data.oldData isnt 'undefined'
      data.newData - data.oldData
    else 
      'na'


  ###*
   * Prepare strings required to show in the sentence
   * ------------------------------------------------------------
   * @name getDisplayInfo
   * @param  {object} data
   * @param  {object} config
   * @return {object} information required to display in the sentence
   * @private
  ###

  getDisplayInfo = (data, configVal) ->
    # Override
    if dataConfig[data.dataType] and dataConfig[data.dataType].getDisplayInfo
      console.log "Override #{data.title} for getDisplayInfo"
      return dataConfig[data.dataType].getDisplayInfo data, configVal

    # Default
    precision = configVal.precision
    result = {}
    result.title = data.title.toLowerCase()
    
    if typeof data.oldData isnt 'undefined'
      result.oldData    = data.oldData.toFixed precision
      result.difference = Math.abs(data.difference).toFixed precision

    result.newData    = data.newData.toFixed(precision)
    
    result


  ###*
   * Calculate the priority of change
   * ------------------------------------------------------------
   * @name calculatePriority
   * @param  {object} data
   * @param  {object} config
   * @return {number} new priority
   * @private
  ###

  calculatePriority = (data, configVal) ->
    # Override
    if dataConfig[data.dataType] and dataConfig[data.dataType].calculatePriority
      console.log "Override #{data.title} for calculatePriority"

      unless typeof data.priority is 'undefined'
        configVal.priority.init = data.priority

      return dataConfig[data.dataType]
            .calculatePriority data.difference, configVal.priority

    # Default
    priorityConfig = configVal.priority

    if data.difference is 'na'
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
   * @param  {object} config
   * @return {number} intensity of the change
   * @private
  ###

  calculateLevel = (data, configVal) ->
    # Override
    if dataConfig[data.dataType] and dataConfig[data.dataType].calculateLevel
      console.log "Override #{data.title} for calculateLevel"
      return dataConfig[data.dataType]
             .calculateLevel data.difference, configVal.level

    # Default
    levelConfig = configVal.level

    if data.difference is 'na'
      level = 'na'
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
      'positive'
    else if level < 0
      'negative'
    else if level is 'na'
      'na'
    else
      'neutral'


  ###*
   * Select number of data to display and sort by priority
   * ------------------------------------------------------------
   * @name selectData
   * @param  {array}  data - array of data
   * @param  {number} nData - number of data to show
   * @return {array}  selected, sorted data by priority
   * @private
  ###

  selectData = (data, nData) ->
    groupedData = groupData data
    result = groupedData.alwaysShow
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

    data = _.groupBy data, 'alwaysShow'
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
    if sentenceConfig[data.sentenceType] \
      and sentenceConfig[data.sentenceType].getSimpleSentenceList
        console.log "Override #{data.title} for getSimpleSentenceList"
        return sentenceConfig[data.sentenceType]
               .getSimpleSentenceList data, simpleSentencese

    # Default
    if typeof sentences.simpleSentences[data.sentenceType] isnt 'undefined' \
      and typeof sentences.simpleSentences[data.sentenceType][data.levelType] isnt 'undefined' \
        and typeof sentences.simpleSentences[data.sentenceType][data.level.toString()] isnt 'undefined'

          if typeof data.oldData isnt 'undefined'
            sentences.simpleSentences[ data.sentenceType ][ data.levelType ][ data.level.toString() ]
          else
            sentences.simpleSentences[ data.sentenceType ][data.levelType ]

    else if typeof data.oldData isnt 'undefined'
      sentences.simpleSentences['default'][ data.levelType ] [data.level.toString() ]
    else
      sentences.simpleSentences['default']['na']


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
   * Combine two simple sentencese that are in the same sentenceGroup
   * ------------------------------------------------------------
   * @name buildCompoundSentence
   * @param  {array}  array of one or two data objects to combine
   * @return {string} a combine sentence
   * @private
  ###

  buildCompoundSentence = (data) ->
    types = _.pluck data, 'levelType'
    type = types.join '_'

    moreDisplayInfo = _.pluck addSimpleSentence(data), 'displayInfo'
    selectedSentences = _.find sentences.compoundSentences, (group) ->
      _.contains group.type, type

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
    data = _.groupBy data, 'contentGroup'

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


  ###*
   * Generate sentences from a list of data
   * ------------------------------------------------------------
   * @name NaturalLanguage.generate
   * @param {number} nData - number of sentences to generate
   * @return {String/Number/Object/Function/Boolean} desc
   * @public
  ###

  generate: (nData) ->
    data = getAttrs @data
    data = selectData data, nData
    # console.log data
    result = buildSentences data
    # console.log result
    return result.join ' '
    

NL = new NaturalLanguage input.data
console.log NL.generate 50