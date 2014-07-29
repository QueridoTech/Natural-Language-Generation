###*
 * ------------------------------------------------------------
 * Prepare resource
 * ------------------------------------------------------------
###
_              = require 'underscore'
# dataConfig     = require './data_config.coffee'
dataConfig = {}
# sentenceConfig = require './sentence_config.coffee'
sentenceConfig = {}
# config         = require './resources/config.json'
config = {
  "default": {
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
}
# sentences      = require './resources/sentences.json'
sentences = {
    "simpleSentences": {
        "default": {
            "na": [
                "{title} is {newData}"
            ],
            "positive": {
                "1": [
                    "{title} has slightly raised to {newData}",
                    "{title} has raised slightly to {newData}",
                    "{title} has increased a bit to {newData}"
                ],
                "2": [
                    "{title} has raised from {oldData} to {newData}",
                    "{title} has raised to {newData}",
                    "{title} has raised for {difference}",
                    "{title} has increased by {difference} to {newData}"
                ],
                "3": [
                    "{title} has significantly increased by {difference} to {newData}",
                    "{title} has extremely raised to {newData}",
                    "{title} has soared from {oldData} to {newData}, a {difference} increase"
                ]
            },
            "neutral": {
                "0": [
                    "{title} is still good at {newData}",
                    "{title} looks good at {newData}"
                ]
            },
            "negative": {
                "-1": [
                    "{title} has slightly dropped to {newData}",
                    "{title} has slightly fallen about {difference}"
                ],
                "-2": [
                    "{title} has dropped from {oldData} to {newData}",
                    "{title} has dropped to {newData}"
                ],
                "-3": [
                    "{title} has significantly decreased by {difference} to {newData}",
                    "{title} has extremely dropped to {newData}"
                ]
            }
        }
    },
    "compoundSentences": {
        "default": [
            {
                "type": [
                    "positive",
                    "neutral",
                    "negative",
                    "na"
                ],
                "sentences": [
                    "{sentence.0}."
                ]
            },
            {
                "type": [
                    "positive_negative",
                    "neutral_negative",
                    "negative_positive"
                ],
                "sentences": [
                    "{sentence.0}, but {sentence.1}."
                ]
            },
            {
                "type": [
                    "positive_positive",
                    "na_na"
                ],
                "sentences": [
                    "{sentence.0}, and {sentence.1}."
                ]
            },
            {
                "type": [
                    "positive_neutral",
                    "negative_negative",
                    "neutral_positive",
                    "neutral_neutral",
                    "negative_neutral"
                ],
                "sentences": [
                    "{sentence.0} and {sentence.1}."
                ]
            }
        ]
    }
}
input          = require './resources/input.json'
words          = require './resources/words.json'


###*
 * Natural Language base class
 * ------------------------------------------------------------
 * @name NaturalLanguage
 * 
 * @constructor
 * @param {Array} data - a list of inputs
###

class NaturalLanguage

  global = null

  constructor: (data) ->
    @data = data
    global = @
    # @generate(nData)


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
      if item.options isnt undefined
        item.options = _.extend(config.default, item.options)
      else
        item.options = config.default
      item.dataType     = 'default' unless item.dataType
      # Custom for more attributes

      if dataConfig[item.dataType] and dataConfig[item.dataType].getAttrs
        console.log "Override #{item.title} for getAttrs"
        item = dataConfig[item.dataType].getAttrs item

      # Default attributes
      item.alwaysShow   = false if typeof item.alwaysShow is 'undefined'
      item.contentGroup = 'default' unless item.contentGroup
      item.sentenceType = 'default' unless item.sentenceType
      item.precision    = 0 unless item.precision != 'undefined'
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
    if dataConfig[data.dataType] and dataConfig[data.dataType].getDifference
      console.log "Override #{data.title} for getDifference"
      return dataConfig[data.dataType].getDifference data

    # Default
    if typeof data.oldData isnt 'undefined' and typeof data.oldData == 'number'
      data.newData - data.oldData
    else 
      'na'


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
    if dataConfig[data.dataType] and dataConfig[data.dataType].getDisplayInfo
      console.log "Override #{data.title} for getDisplayInfo"
      return dataConfig[data.dataType].getDisplayInfo data

    # Default
    result = {}
    result.title = data.title.toLowerCase()
    
    if typeof data.oldData isnt 'undefined'
      if typeof data.oldData == 'number'
        result.oldData    = data.oldData.toFixed data.precision
      else
        result.oldData = data.oldData.toLowerCase()
      if typeof data.difference == 'number'
        result.difference = Math.abs(data.difference).toFixed data.precision
    if typeof data.newData == 'number'
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
    if dataConfig[data.dataType] and dataConfig[data.dataType].calculatePriority
      console.log "Override #{data.title} for calculatePriority"

      unless typeof data.priority is 'undefined'
        data.options.priority.init = data.priority

      return dataConfig[data.dataType]
            .calculatePriority data.difference, data.options.priority

    # Default
    priorityConfig = data.options.priority

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
   * @return {number} intensity of the change
   * @private
  ###

  calculateLevel = (data) ->
    # Override
    if dataConfig[data.dataType] and dataConfig[data.dataType].calculateLevel
      console.log "Override #{data.title} for calculateLevel"
      return dataConfig[data.dataType]
             .calculateLevel data.difference, data.options.level

    # Default
    levelConfig = data.options.level

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
    if typeof data.oldData is 'undefined' # No oldData
      if typeof sentences.simpleSentences[data.sentenceType] isnt 'undefined' \
        and typeof sentences.simpleSentences[data.sentenceType]['na'] isnt 'undefined'
          sentences.simpleSentences[data.sentenceType]['na']
      else
        sentences.simpleSentences['default']['na']
    else
      if typeof sentences.simpleSentences[data.sentenceType] isnt 'undefined' \
        and typeof sentences.simpleSentences[data.sentenceType][data.levelType] isnt 'undefined'
          if typeof sentences.simpleSentences[data.sentenceType][data.levelType][data.level.toString()] isnt 'undefined'
            sentences.simpleSentences[ data.sentenceType ][ data.levelType ][ data.level.toString() ]
          else
            sentences.simpleSentences[ data.sentenceType ][ data.levelType ]
      else
        sentences.simpleSentences['default'][ data.levelType ][ data.level.toString() ]


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
    # console.log data
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
    if(sentenceConfig[data.sentenceType] && sentenceConfig[data.sentenceType].getCompoundSentenceList)
      console.log("Override " + data.title + " for getSimpleSentenceList")
      return sentenceConfig[data.sentenceType].getCompoundSentenceList(data, compoundSentences)
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
    types = _.pluck data, 'levelType'
    type = types.join '_'

    moreDisplayInfo = _.pluck addSimpleSentence(data), 'displayInfo'
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

  addType: (title, func = {}) ->
    if dataConfig[title]
      dataConfig[title] = _.extend(dataConfig[title], func)
    else 
      dataConfig[title] = func

  addSentence: (title, func = null) ->
    if sentenceConfig[title]
      sentenceConfig[title] = _.extend(sentenceConfig[title], func)
    else 
      sentenceConfig[title] = func

  ###*
   * Generate sentences from a list of data
   * ------------------------------------------------------------
   * @name NaturalLanguage.generate
   * @param {number} nData - number of sentences to generate
   * @return {String/Number/Object/Function/Boolean} desc
   * @public
  ###
  generate: (nData = -1) ->
    data = getAttrs @data
    # console.log data
    data = selectData data, nData
    # console.log data
    result = buildSentences data
    # console.log result
    return result.join ' '

# NL = new NaturalLanguage [{
#       "title": "Growth Opportunity",
#       "newData": 60,
#       "alwaysShow": false
#     }]
# NL = new NaturalLanguage [{
#       "title": "Growth Opportunity",
#       "newData": 60,
#       "oldData": 90,
#       "alwaysShow": false
#     }]
# NL = new NaturalLanguage [{
#       "title": "Growth Opportunity",
#       "newData": 60,
#       "oldData": 90,
#       "alwaysShow": false,
#       "options": {
#         "priority": {
#           "init": 1,
#           "negativeFactor": 0.1,
#           "positiveFactor": 0.1
#         },
#         "level": {
#           "threshold": 5,
#           "sensitiveness": 10
#         }
#       }
#     }]
# NL = new NaturalLanguage [{
#       "title": "Operating Margin",
#       "newData": "Declined",
#       "alwaysShow": false
# }]
# NL = new NaturalLanguage [{
#       "title": "Operating Margin",
#       "oldData": "-",
#       "newData": "Declined",
#       "alwaysShow": false
# }]
# NL = new NaturalLanguage [{
#       "title": "Share Repurchase",
#       "newData": "Every year",
#       "alwaysShow": false,
#       "dataType": "sign",
#       "sentenceType": "repurchase"
# }]
# NL = new NaturalLanguage [{
#       "title": "Share Repurchase",
#       "oldData": "Every year",
#       "newData": "Every year",
#       "alwaysShow": false,
#       "dataType": "sign",
#       "sentenceType": "repurchase"
# }]
# NL = new NaturalLanguage [
#   {
#     "title": "Share Repurchase",
#     "oldData": "Every year",
#     "newData": "Every year",
#     "alwaysShow": false,
#     "dataType": "sign",
#     "sentenceType": "repurchase"
#   },
#   {
#     "title": "Growth Opportunity",
#     "newData": 60,
#     "oldData": 90,
#     "alwaysShow": false
#   }
# ]
NL = new NaturalLanguage [
  {
    "title": "Share Repurchase",
    "oldData": "Every year",
    "newData": "Every year",
    "dataType": "sign",
    "sentenceType": "repurchase",
    "contentGroup": "sign"
  },
  {
    "title": "Growth Opportunity",
    "newData": 60,
    "oldData": 90,
    "contentGroup": "factor"
  },
  {
    "title": "Financial Strength",
    "oldData": 100,
    "newData": 100,
    "contentGroup": "factor",
    "alwaysShow": true
  }
]
# NL = new NaturalLanguage [{
#       "title": "Share Repurchase",
#       "oldData": "-",
#       "newData": "Every year",
#       "alwaysShow": false,
#       "dataType": "sign"
# }]
# NL.addType "Share Repurchase", {

# }
# NL = new NaturalLanguage [{
#       "title": "Price",
#       "newData": 80.20,
#       "currency": "baht",
#       "alwaysShow": false
# }]
NL.addType "sign", {
  words: {
    "Revenue and Earning": {
      "Consistent": "+1",
      "Consistent Growth": "+2", 
      "Consistently High Growth": "+3",
      "-": "0",
      "Revenue loss detected in the past years": "-2",
      "Earning loss detected in the past years": "-2",
      "Revenue Declined": "-1",
      "Earning Declined": "-1"
    },
    "Operating Margin": {
      "-": "0",
      "Consistent": "+1",
      "Expansion": "+2",
      "Inconsistent": "-1",
      "Declined": "-2"
    },
    "Debt Level": {
      "-": "0",
      "Low .*": "+1",
      "No .*": "+2",
      "High .* in the past 5 years": "-1",
      "High .*": "-2",
      "Very High .*": "-3"
    },
    "Recent Business Performance":{
      "-": "0",
      "Earning decline detected in the last 4 quarters": "-3",
      "Earning declined in the last quarter": "-1",
      "Earning declined in the last year": "-2"
    },
    "Return on Equity": {
      "-": "0",
      "Consistently High": "+2"
    },
    "Dividend Payout": {
      "-": "0",
      "Every year": "+1",
      "Increasing Every Year": "+2"
    },
    "Share Repurchase": {
      "-": "0",
      "Every year": "+2"
    },
    "CapEx": {
      "-": "0",
      "Very Low": "+2",
      "Very High": "-2"
    },
    "Recent IPO": {
      "-": "0",
      "Less than 3 years": "+1"
    },
    "New Share Issued": {
      "-": "0",
      "More than 50% in 5 years": "-2"
    }
  },
  getAttrs: (data) ->
    data.newScore = @getScore(data.title, data.newData)
    if(typeof data.oldData != "undefined")
      data.oldScore = @getScore(data.title, data.oldData)
    if(data.newScore == '0')
      data.hidden = true
    data

  getDisplayInfo: (data) ->
    precision = data.precision
    result = {}
    result.title = data.title.toLowerCase()
    result.title = "CapEx" if data.title == "CapEx"
    result.newData = data.newData.toLowerCase()
    if(typeof data.oldData != "undefined")
      result.oldData = data.oldData.toLowerCase()
    result

  getScore: (title, data) ->
    for item of @words[title]
      pattern = new RegExp(item, "g");
      if pattern.test(data)
        return @words[title][item]
    return null

  getDifference: (data) ->
    if(typeof data.oldData != "undefined")
      parseInt(data.newScore) - parseInt(data.oldScore)
    else
      "na"  
}
NL.addSentence "repurchase", {
  simpleSentences: {
    "+2": {
        "+2": [
            "there is still {title} {newData}"
        ]
    },
    "0": {
        "+2": [
            "there is {title} {newData}"
        ]
    }
  }
  getSimpleSentenceList: (data, simpleSentences) ->
    oldScore = if typeof data.oldScore == "undefined" then 0 else data.oldScore
    @simpleSentences[oldScore][data.newScore]
}
# NL.addType "Price", {
#     "priority": {
#       "init": 10,
#       "negativeFactor": 2,
#       "positiveFactor": 1
#     },
#     "level": {
#       "threshold": 5,
#       "sensitiveness": 5
#     },
#     "dataType": "price",
#     "sentenceType": "default",
#     "contentGroup": "price",
#     "precision": 0
#   }
console.log NL.generate(2)