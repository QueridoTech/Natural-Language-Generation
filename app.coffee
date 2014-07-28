(function() {
dataConfig     = require("./data_config.coffee")
sentenceConfig = require("./sentence_config.coffee")
config         = require("./resources/config.json")
sentences      = require("./resources/sentences.json")
input          = require("./resources/input2.json")
_              = require("underscore")

###
# Data Preparation
###

###
Generate sentences from a list of data
@param  {array}  data - a list of inputs
@param  {number} nData - number of sentences to generate
@return {string} output sentences
###
generate = (data, nData) ->
  data = getAttrs(data)
  data = selectData(data, nData)
  # console.log data
  result = buildSentences(data)
  # console.log result
  return result.join(' ')

###
Add more required attributes
@param  {array}  data - array of inputs
@return {object} new data with more attributes
###
getAttrs = (data) ->
  for i of data

    if(config[data[i].title])
      name = data[i].title
    else
      name = 'default'
    dataType = config[name].dataType

    # Custom for more attributes
    if(dataConfig[dataType] && dataConfig[dataType].getAttrs)
      console.log("Override " + data[i].title + " for getAttrs")
      data[i] = dataConfig[dataType].getAttrs(data[i])

    # Default attributes
    data[i].dataType     = dataType
    data[i].difference   = getDifference(data[i])
    data[i].sentenceType = config[name].sentenceType
    data[i].contentGroup = config[name].contentGroup
    data[i].displayInfo  = getDisplayInfo(data[i], config[name])
    data[i].priority     = calculatePriority(data[i], config[name])
    data[i].level        = calculateLevel(data[i], config[name])
    data[i].levelType    = calculateType(data[i].level)
  data

###
Get the difference between old value and current value
@param  {object}        data
@return {number/string} difference value
###
getDifference = (data) ->
  # Override
  if(dataConfig[data.dataType] && dataConfig[data.dataType].getDifference)
    console.log("Override " + data.title + " for getDifference")
    return dataConfig[data.dataType].getDifference(data)
  # Default
  if(typeof data.oldData != 'undefined')
    data.newData - data.oldData
  else 
    'na'

###
Prepare strings required to show in the sentence
@param  {object} data
@param  {object} config
@return {object} information required to display in the sentence
###
getDisplayInfo = (data, configVal) ->
  # Override
  if(dataConfig[data.dataType] && dataConfig[data.dataType].getDisplayInfo)
    console.log("Override " + data.title + " for getDisplayInfo")
    return dataConfig[data.dataType].getDisplayInfo(data, configVal)
  # Default
  precision = configVal.precision
  result = {}
  result.title      = data.title.toLowerCase()
  if(typeof data.oldData != 'undefined')
    result.oldData    = data.oldData.toFixed(precision)
    result.difference = Math.abs(data.difference).toFixed(precision)
  result.newData    = data.newData.toFixed(precision)
  result

###
Calculate the priority of change
@param  {object} data
@param  {object} config
@return {number} new priority
###
calculatePriority = (data, configVal) ->
  # Override
  if(dataConfig[data.dataType] && dataConfig[data.dataType].calculatePriority)
    console.log("Override " + data.title + " for calculatePriority")
    configVal.priority.init = data.priority if(! typeof(data.priority) == undefined)
    return dataConfig[data.dataType].calculatePriority(data.difference, configVal.priority)
  # Default
  priorityConfig = configVal.priority
  if(data.difference == 'na')
    return priorityConfig.init
  else if(data.difference > 0)
    newPriority = priorityConfig.init + (priorityConfig.positiveFactor * data.difference)
  else
    newPriority = priorityConfig.init + (priorityConfig.negativeFactor * Math.abs(data.difference))
  parseInt(newPriority.toFixed(0))

###
Calculate the intesity of change
@param  {object} data
@param  {object} config
@return {number} intensity of the change
###
calculateLevel = (data, configVal) ->
  # Override
  if(dataConfig[data.dataType] && dataConfig[data.dataType].calculateLevel)
    console.log("Override " + data.title + " for calculateLevel")
    return dataConfig[data.dataType].calculateLevel(data.difference, configVal.level)
  # Default
  levelConfig = configVal.level
  if data.difference == 'na'
    level = 'na'
  else
    absoluteDifference = Math.abs(data.difference)
    if(absoluteDifference < levelConfig.threshold)
      level = 0
    else
      level = Math.ceil(data.difference/levelConfig.sensitiveness)
      level = 3 if(level > 3)
      level = -3 if(level < -3)
  level

###
Calculate the type of intesity
@param  {number} level
@return {string} levelType
###
calculateType = (level) ->
  if level > 0
    'positive'
  else if level < 0
    'negative'
  else if level == 'na'
    'na'
  else
    'neutral'

###
Select number of data to display and sort by priority
@param  {array}  data - array of data
@param  {number} nData - number of data to show
@return {array}  selected, sorted data by priority
###
selectData = (data, nData) ->
  groupedData = groupData(data)
  result = groupedData.alwaysShow
  if result.length < nData
    nRemaining = nData - result.length
    result = result.concat(groupedData.sortedData.slice(0, nRemaining))
  result.sort (a, b) ->
    b.priority - a.priority

  result

###
Group data by alwaysShow attr and sort the group by priority
@param  {array} data - array of data
@return {array} data split into two groups, alwaysShow and sortedData
###
groupData = (data) ->
  # Remove hidden items
  data = _.filter(data, (item) ->
    ! item.hidden
  )
  data = _.groupBy(data, "alwaysShow")
  data.sortedData = []
  data.alwaysShow = []
  if data[false]
    data[false].sort (a, b) ->
      b.priority - a.priority

    data.sortedData = data[false]
  data.alwaysShow = data[true] if data[true]
  data

###
# Sentence Generation
###

###
Group data into contentGroups and loop through each
contentGroup to create sentence(s)
@param  {array} data - array sorted by priority but not grouped
@return {array} array of sentences
###
buildSentences = (data) ->
  result = []
  data = _.groupBy(data, "contentGroup")
  for group of data
    if(data[group].length > 2)
      i = 0
      while i < data[group].length
        if i + 1 is data[group].length
          result.push(buildCompoundSentence([data[group][i]]))
        else
          result.push(buildCompoundSentence([data[group][i], data[group][parseInt(i)+1]]))
        i = i + 2
    else
      result.push(buildCompoundSentence(data[group]))
  result

###
Group data into contentGroups and loop through each
contentGroup to create sentence(s)
@param  {object} data - data object
@return {array}  array of sentences
###
buildSimpleSentence = (data) ->
  simpleSentences = getSimpleSentenceList(data, sentences.simpleSentences)
  replaceStr(simpleSentences, data.displayInfo)

###
Get a valid list of sentences for random selecting
@param  {object} data - data object
@param  {array}  simpleSentences - sentences from all types
@return {array}  array of valid sentences
###
getSimpleSentenceList = (data, simpleSentences) ->
  # Override
  if(sentenceConfig[data.sentenceType] && sentenceConfig[data.sentenceType].getSimpleSentenceList)
    console.log("Override " + data.title + " for getSimpleSentenceList")
    return sentenceConfig[data.sentenceType].getSimpleSentenceList(data, simpleSentences)
  # Default
  if(typeof simpleSentences[data.sentenceType] != 'undefined' && typeof simpleSentences[data.sentenceType][data.levelType] != 'undefined' && typeof simpleSentences[data.sentenceType][data.level.toString()] != 'undefined')
    if typeof data.oldData != 'undefined'
      simpleSentences[data.sentenceType][data.levelType][data.level.toString()]
    else
      simpleSentences[data.sentenceType][data.levelType]
  else if typeof data.oldData != 'undefined'
    simpleSentences['default'][data.levelType][data.level.toString()]
  else
    simpleSentences['default']['na']

###
Get a valid list of compound sentences
@param  {object} data - data object
@param  {array}  compoundSentences - sentences from all types
@return {array}  array of valid sentences
###
getCompoundSentenceList = (data, compoundSentences) ->
  # Override
  if(sentenceConfig[data.sentenceType] && sentenceConfig[data.sentenceType].getCompoundSentenceList)
    console.log("Override " + data.title + " for getSimpleSentenceList")
    return sentenceConfig[data.sentenceType].getCompoundSentenceList(data, compoundSentences)
  # Default
  if(typeof compoundSentences[data.sentenceType] != 'undefined')
    compoundSentences[data.sentenceType]
  else
    compoundSentences['default']

###
Combine two simple sentencese that are in the same sentenceGroup
@param  {array}  array of one or two data objects to combine
@return {string} a combine sentence
###
buildCompoundSentence = (data) ->
  types = _.pluck(data, 'levelType');
  type = types.join('_')
  moreDisplayInfo = _.pluck(addSimpleSentence(data), 'displayInfo');
  compoundSentences = getCompoundSentenceList(data, sentences.compoundSentences)
  selectedSentences = _.find(compoundSentences, (group) ->
    _.contains(group.type, type);
  )
  capitalize(replaceCombinedStr(selectedSentences.sentences, moreDisplayInfo))

###
Add simple sentence into the data object
@param  {array} array of data to generate simple sentences
@return {array} array of data with sentence attribute inserted
###
addSimpleSentence = (data) ->
  for i of data
    data[i].displayInfo.sentence = buildSimpleSentence(data[i])
  data

###
Replace sentence pattern with string in data object
(single sentence, no capitalization or full stop)
@param  {array}  patterns - array of sentences
@param  {object} data - displayInfo object
@return {string} final sentence
###
replaceStr = (patterns, data) ->
  pattern = _.sample(patterns)
  for key of data
    pattern = pattern.replace("{" + key + "}", data[key])
  pattern

###
Replace sentence pattern with string in data object
(combined sentence, with capitalization and full stop)
@param  {array}  patterns - array of sentences
@param  {array}  data - array of displayInfo object
@return {string} final sentence
###
replaceCombinedStr = (patterns, data) ->
  pattern = _.sample(patterns)
  for i of data
      for key of data[i]
        pattern = pattern.replace("{" + key + "." + i + "}", data[i][key])
  pattern

###
Change the first character of the string to capital
@param  {string} data
@return {string} capitalized string
###
capitalize = (data) ->
  data.charAt(0).toUpperCase() + data.slice(1);
}.call(this));

console.log generate(input.data, 3)
