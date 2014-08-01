assert = require('assert')
{NaturalLanguage} = require('../src/main')


NL = new NaturalLanguage [{
  "title": "Growth Opportunity",
  "newData": 60
}]

# Basic integer
assert.equal NL.generate(), "Growth opportunity is 60."

# Basic integer with no random
assert.equal NL.generate(-1, false), "Growth opportunity is 60."

# Basic integer with 0 data
assert.equal NL.generate(0, false), ""

NL = new NaturalLanguage [{
  "title": "Growth Opportunity",
  "newData": 60,
  "oldData": 90
}]
# Integer with oldData to compare with
assert.equal NL.generate(-1, false), "Growth opportunity has significantly decreased by 30 to 60."

NL = new NaturalLanguage [{
  "title": "Growth Opportunity",
  "newData": 60,
  "oldData": 90,
  "options": {
    "priority": {
      "init": 1,
      "negativeFactor": 0.1,
      "positiveFactor": 0.1
    },
    "level": {
      "threshold": 5,
      "sensitiveness": 30
    }
  }
}]
# Integer with custom options
# assert.equal NL.generate(-1, false), "Growth opportunity has slightly dropped to 60."
NL.generate(-1, false)

NL = new NaturalLanguage [{
  "title": "Operating Margin",
  "newData": "Declined"
}]
# Basic string
assert.equal NL.generate(-1, false), "Operating margin is declined."

NL = new NaturalLanguage [{
  "title": "Operating Margin",
  "oldData": "-",
  "newData": "Declined"
}]
# String with oldData to compare with
assert.equal NL.generate(-1, false), "Operating margin is declined."

NL = new NaturalLanguage [{
  "title": "Share Repurchase",
  "newData": "Every year",
  "alwaysShow": false,
  "dataType": "sign"
}]
signType = {
  words: {
    "Debt Level": {
      "-": "0",
      "Low .*": "+1",
      "No .*": "+2",
      "High .* in the past 5 years": "-1",
      "High .*": "-2",
      "Very High .*": "-3"
    },
    "Share Repurchase": {
      "-": "0",
      "Every year": "+2"
    },
    "CapEx": {
      "-": "0",
      "Very Low": "+2",
      "Very High": "-2"
    }
  },
  setAttrs: (data) ->
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
      pattern = new RegExp(item, "g")
      if pattern.test(data)
        return @words[title][item]
    return null

  getDifference: (data) ->
    if(typeof data.oldData != "undefined")
      parseInt(data.newScore) - parseInt(data.oldScore)
    else
      "na"
}
NL.addType "sign", signType
# String with custom functions
assert.equal NL.generate(-1, false), "Share repurchase is every year."

NL = new NaturalLanguage [{
  "title": "Share Repurchase",
  "oldData": "-",
  "newData": "Every year",
  "dataType": "sign"
}]
NL.addType "sign", signType
# String with custom functions + oldData
assert.equal NL.generate(-1, false), "Share repurchase has raised from - to every year."

NL = new NaturalLanguage [{
  "title": "Share Repurchase",
  "newData": "Every year",
  "dataType": "sign",
  "sentenceType": "repurchase"
}]
repurchaseSentence = {
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
NL.addType "sign", signType
NL.addSentence "repurchase", repurchaseSentence
# Use custom functions and custom sentences
assert.equal NL.generate(-1, false), "There is share repurchase every year."

NL = new NaturalLanguage [{
  "title": "Share Repurchase",
  "oldData": "Every year",
  "newData": "Every year",
  "dataType": "sign",
  "sentenceType": "repurchase"
}]
NL.addType "sign", signType
NL.addSentence "repurchase", repurchaseSentence
# Custom functions + sentences + oldData
assert.equal NL.generate(-1, false), "There is still share repurchase every year."

NL = new NaturalLanguage [
  {
    "title": "Share Repurchase",
    "oldData": "Every year",
    "newData": "Every year",
    "dataType": "sign",
    "sentenceType": "repurchase"
  },
  {
    "title": "Growth Opportunity",
    "newData": 60,
    "oldData": 90
  }
]
NL.addType "sign", signType
NL.addSentence "repurchase", repurchaseSentence
# Multiple sentences
assert.equal NL.generate(-1, false), "Growth opportunity has significantly decreased by 30 to 60 and there is still share repurchase every year."

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
  }
]
NL.addType "sign", signType
NL.addSentence "repurchase", repurchaseSentence
# Separate data into groups
assert.equal NL.generate(-1, false), "Growth opportunity has significantly decreased by 30 to 60. There is still share repurchase every year."

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
    "contentGroup": "factor"
  }
]
NL.addType "sign", signType
NL.addSentence "repurchase", repurchaseSentence
# Extra example
assert.equal NL.generate(-1, false), "Growth opportunity has significantly decreased by 30 to 60 and financial strength is still good at 100. There is still share repurchase every year."
# Show only two pieces of data
assert.equal NL.generate(2, false), "Growth opportunity has significantly decreased by 30 to 60. There is still share repurchase every year."

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
    "alwaysShow": true # Force this data to display
  }
]
NL.addType "sign", signType
NL.addSentence "repurchase", repurchaseSentence
# Always show this data no matter what
assert.equal NL.generate(2, false), "Growth opportunity has significantly decreased by 30 to 60 and financial strength is still good at 100."