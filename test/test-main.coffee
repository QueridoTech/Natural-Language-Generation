assert = require('assert')
{NaturalLanguage} = require('../src/main')


NL = new NaturalLanguage [{
  "title": "Growth Opportunity",
  "newData": 60
}]

# Basic integer
assert.equal(NL.generate(), "Growth opportunity is 60.")
# console.log(NL.generate(), "Growth opportunity is 60.")

# Basic integer with no random
assert.equal(NL.generate(-1, false), "Growth opportunity is 60.")
# console.log(NL.generate(-1, false), "Growth opportunity is 60.")

# Basic integer with 0 data
assert.equal(NL.generate(0, false), "")
# console.log(NL.generate(0, false), "")

NL = new NaturalLanguage [{
  "title": "Growth Opportunity",
  "newData": 60,
  "oldData": 90
}]
# Integer with oldData to compare with
assert.equal(NL.generate(-1, false), "Growth opportunity has significantly decreased by 30 to 60.")
# console.log(NL.generate(-1, false), "Growth opportunity has significantly decreased by 30 to 60.")

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
assert.equal(NL.generate(-1, false), "Growth opportunity has slightly dropped to 60.")
# console.log(NL.generate(-1, false), "Growth opportunity has slightly dropped to 60.")

NL = new NaturalLanguage [{
  "title": "Operating Margin",
  "newData": "Declined"
}]
# Basic string
assert.equal(NL.generate(-1, false), "Operating margin is declined.")
# console.log(NL.generate(-1, false), "Operating margin is declined.")

NL = new NaturalLanguage [{
  "title": "Operating Margin",
  "oldData": "-",
  "newData": "Declined"
}]
# String with oldData to compare with
assert.equal(NL.generate(-1, false), "Operating margin is declined.")
# console.log(NL.generate(-1, false), "Operating margin is declined.")

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
assert.equal(NL.generate(-1, false), "Share repurchase is every year.")
# console.log(NL.generate(-1, false), "Share repurchase is every year.")

NL2 = new NaturalLanguage [{
  "title": "Share Repurchase",
  "oldData": "-sss",
  "newData": "Every year",
  "dataType": "sign"
}]
NL2.addType "sign", signType
# String with custom functions + oldData
# console.log NaturalLanguage.sentences
# console.log NL2.generate(-1, false)
assert.equal(NL2.generate(-1, false), "Share repurchase has raised from - to every year.")
# console.log(NL2.generate(-1, false), "Share repurchase has raised from - to every year.")
# assert.equal(NL.generate(-1, false), "Growth opportunity has extremely dropped to 60.")