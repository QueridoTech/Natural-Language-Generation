{NaturalLanguage} = require "./main"
input = require './resources/input2.json'
NL = new NaturalLanguage input.data

# Jitta Line
NL.addType "jittaline", {
  setAttrs: (data) ->
    data.oldNumber = @getNumber(data.oldData) if(typeof data.oldData != 'undefined')
    data.newNumber = @getNumber(data.newData)
    data

  getDifference: (data) ->
    if(typeof data.oldData != 'undefined')
      data.newNumber - data.oldNumber
    else
      'na'

  getNumber: (data) ->
    percentIndex = data.indexOf("%")
    status = data.substring(percentIndex + 2, percentIndex + 7)
    number = data.substring(0, percentIndex)
    number = number * -1  if status is "Below"
    number

  getStatus: (data) ->
    percentIndex = data.indexOf("%")
    data.substring(percentIndex + 2, percentIndex + 7)

  getDisplayInfo: (data) ->
    precision = data.precision
    result = {}
    result.title = "the price"
    result.newData = data.newData.toLowerCase()
    result.newNumber = Math.abs(data.newNumber.toFixed(precision))
    result.newLine = if data.newNumber < 0 then 'below' else 'above'
    if(typeof data.oldData != 'undefined')
        result.oldData = data.oldData.toLowerCase()
        result.oldNumber = Math.abs(data.oldNumber.toFixed(precision))
        result.oldLine = if data.oldNumber < 0 then 'below' else 'above'
        difference = data.newNumber - data.oldNumber
        result.difference = Math.abs(difference.toFixed(if difference.toFixed(0) == 0 then 2 else precision))
    result
}

# Price
NL.addType "price", {
  getDifference: (data) ->
    if(typeof data.oldData != 'undefined')
      ((data.newData - data.oldData)/data.oldData)*100
    else
      'na'

  getDisplayInfo: (data) ->
    precision = data.precision
    result = {}
    result.title = "the " + data.title.toLowerCase()
    if(typeof data.oldData != 'undefined')
      percentDiff = Math.abs(data.difference)
      result.oldData = data.oldData.toFixed(precision) + " " + data.currency
      result.differencePrice = Math.abs(data.newData - data.oldData).toFixed(precision) + " " + data.currency
      result.difference = percentDiff.toFixed(if percentDiff.toFixed(0) == 0 then 2 else precision) + "%"
    result.newData = data.newData.toFixed(precision) + " " + data.currency
    result
}

# Jitta Score
NL.addType "score", {
  getDisplayInfo: (data) ->
    precision = data.precision
    result = {}
    result.title = data.title.charAt(0).toUpperCase() + data.title.slice(1).toLowerCase()
    if(typeof data.oldData != 'undefined')
        result.oldData = data.oldData.toFixed(precision)
        result.difference = Math.abs(data.difference).toFixed(precision)
    result.newData = data.newData.toFixed(precision)
    result
}

# Type: Loss Chance
NL.addType "loss", {
  getDisplayInfo: (data) ->
    precision = data.precision
    result = {}
    result.title = data.title.toLowerCase()
    result.newData = data.newData.toFixed(precision) + "%"
    if(typeof data.oldData != 'undefined')
      result.oldData = data.oldData.toFixed(precision) + "%"
      absoluteDifference = Math.abs(data.difference)
      precision = 2 if absoluteDifference.toFixed(0) == "0"
      result.difference = absoluteDifference.toFixed(precision) + "%"
    result
}

# Type: Jitta Signs
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

# Type: Error
NL.addType "error", {
  getDisplayInfo: (data) ->
    result = {}
    result.title = data.title
    result.newData = data.newData.toLowerCase()
    result
}

# Sentence: Jitta Line
NL.addSentence "jittaline", {
  simpleSentences: {
    "above_above": {
        "0": [
            "{title} has changed from {oldNumber}% to {newData}"
        ],
        "1": [
            "{title} has slightly changed from {oldNumber}% to {newData}",
            "{title} has slightly raised from {oldNumber}% to {newData}"
        ],
        "2": [
            "{title} has changed from {oldNumber}% to {newData}"
        ],
        "3": [
            "{title} has raised from {oldNumber}% to {newData}",
            "{title} has improved from {oldNumber}% to {newData}"
        ],
        "-1": [
            "{title} has slightly decreased from {oldNumber}% to {newData}"
        ],
        "-2": [
            "{title} has fallen to {newData}",
            "{title} has decreased from {oldNumber}% to {newData}"
        ],
        "-3": [
            "{title} has changed from {oldNumber}% to {newData}"
        ]
    },
    "above_below": {
        "0": [
            "{title} has fallen from {oldData} to {newData}"
        ],
        "-3": [
            "{title} has fallen from {oldData} to {newData}"
        ],
        "-2": [
            "{title} has fallen from {oldData} to {newData}"
        ],
        "-1": [
            "{title} has fallen from {oldData} to {newData}"
        ]
    },
    "below_above": {
        "0": [
            "{title} has improved from {oldData} to {newData}"
        ],
        "1": [
            "{title} has improved from {oldData} to {newData}"
        ],
        "2": [
            "{title} has improved from {oldData} to {newData}"
        ],
        "3": [
            "{title} has improved from {oldData} to {newData}"
        ]
    },
    "below_below": {
        "0": [
            "{title} has changed from {oldNumber}% to {newData}"
        ],
        "1": [
            "{title} has slightly changed from {oldNumber}% to {newData}",
            "{title} has slightly upgraded from {oldNumber}% to {newData}"
        ],
        "2": [
            "{title} has changed from {oldNumber}% to {newData}",
            "{title} has upgraded from {oldNumber}% to {newData}"
        ],
        "3": [
            "{title} has improved from {oldNumber}% to {newData}",
            "{title} has jumped from {oldNumber}% to {newData}"
        ],
        "-1": [
            "{title} has slightly decreased from {oldNumber}% to {newData}"
        ],
        "-2": [
            "{title} has fallen to {newData}"
        ],
        "-3": [
            "{title} has decreased from {oldNumber}% to {newData}"
        ]
    }
  },
  getSimpleSentenceList: (data, simpleSentences) ->
    if typeof data.displayInfo.oldLine != 'undefined'
      group = data.displayInfo.oldLine + "_" + data.displayInfo.newLine
      @simpleSentences[group][data.level]
    else
      simpleSentences.default.na
}

# Sentence: Earning
NL.addSentence "earning", {
  simpleSentences: {
    "+1": [
        "{title} is still {newData}"
    ],
    "+2": [
        "{newData} in {title}"
    ],
    "+3": [
        "{newData} in {title}"
    ],
    "-2": [
        "{newData}"
    ],
    "-1": [
        "{newData}"
    ],
    "0": [
        "No update in {title}"
    ]
  },
  getSimpleSentenceList: (data, simpleSentences) ->
    @simpleSentences[data.newScore]
}

# Sentence: Operating
NL.addSentence "operating", {
  simpleSentences: {
    "na": [
        "{title} is {newData}"
    ],
    "positive": [
        "{title} is {newData}"
    ],
    "neutral": [
        "{title} is still {newData}"
    ],
    "negative": [
        "{title} is {newData}"
    ]
  },
  getSimpleSentenceList: (data, simpleSentences) ->
    @simpleSentences[data.levelType]
}

# Sentence: Debt
NL.addSentence "debt", {
  simpleSentences: {
    "all": [
        "there is {newData}"
    ]
  },
  getSimpleSentenceList: (data, simpleSentences) ->
    @simpleSentences.all
}

# Sentence: Return on Equity
NL.addSentence "roe", {
  simpleSentences: {
    "+2": {
        "+2": [
            "{title} is still {newData}"
        ]
    },
    "0": {
        "+2": [
            "{title} is {newData}"
        ]
    }
  },
  getSimpleSentenceList: (data, simpleSentences) ->
    oldScore = if typeof data.oldScore == 'undefined' then 0 else data.oldScore
    if(@simpleSentences[oldScore] && @simpleSentences[oldScore][data.newScore])
      @simpleSentences[oldScore][data.newScore]
    else
      ["Error #{data.title}"]
}

# Sentence: Dividend Payout
NL.addSentence "dividend", {
  simpleSentences: {
    "positive": [
        "{title} is {newData}"
    ],
    "neutral": [
        "{title} is still {newData}"
    ],
    "negative": [
        "{title} is {newData}"
    ],
    "na": [
        "{title} is {newData}"
    ]
  },
  getSimpleSentenceList: (data, simpleSentences) ->
    if(@simpleSentences[data.levelType])
      @simpleSentences[data.levelType]
    else
      ["Error #{data.title}"]
}

# Sentence: CapEx
NL.addSentence "capex", {
  simpleSentences: {
    "na": [
        "{title} is {newData}"
    ],
    "positive": [
        "{title} is {newData}"
    ],
    "neutral": [
        "{title} is still {newData}"
    ],
    "negative": [
        "{title} is {newData}"
    ]
  },
  getSimpleSentenceList: (data, simpleSentences) ->
    @simpleSentences[data.levelType]
}

# Sentence: Repurchase
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


console.log NL.generate()