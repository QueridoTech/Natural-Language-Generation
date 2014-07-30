Natural-Language-Generation
===========================
- Run ```coffee app.coffee```
- For Jitta, run ```coffee jitta_example.coffee```

Sample output:
--------------

#### Short

The price has decreased from 53% to 62.62% below jitta line. Jitta score looks good at 7.0. The price has significantly decreased by 16% to 80 baht. CapEx is very low, and there is share repurchase every year.

#### Full

The price has decreased from 53% to 62.62% below jitta line. Jitta score is still good at 7.0. The price has extremely dropped to 80 baht. CapEx is very low, and there is share repurchase every year. Operating margin is declined, but dividend payout is increasing every year. There is return on equity, but earning loss detected in the past years. Return on equity is still consistently high. Growth opportunity has significantly decreased by 30 to 60, but competitive advantage has increased by 2 to 100. Recent business performance has raised from 35 to 50 and return to share holder is still good at 69. Financial strength is still good at 100.

Usage:
------

#### Basic integer
```
NL = new NaturalLanguage [{
  "title": "Growth Opportunity",
  "newData": 60
}]
console.log NL.generate()
# Output: Growth opportunity is 60.
```

#### Integer with oldData to compare with
```
NL = new NaturalLanguage [{
  "title": "Growth Opportunity",
  "newData": 60,
  "oldData": 90
}]
console.log NL.generate()
# Output: Growth opportunity has significantly decreased by 30 to 60.
```

#### Integer with custom options
```
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
      "sensitiveness": 10
    }
  }
}]
console.log NL.generate()
# Output: Growth opportunity has significantly decreased by 30 to 60.
```

#### Basic string
```
NL = new NaturalLanguage [{
  "title": "Operating Margin",
  "newData": "Declined"
}]
console.log NL.generate()
# Output: Operating margin is declined.
```

#### String with oldData to compare with
```
NL = new NaturalLanguage [{
  "title": "Operating Margin",
  "oldData": "-",
  "newData": "Declined"
}]
console.log NL.generate()
# Output: Operating margin is declined.
```

#### String with custom functions
```
NL = new NaturalLanguage [{
      "title": "Share Repurchase",
      "newData": "Every year",
      "alwaysShow": false,
      "dataType": "sign"
}]
NL.addType "sign", {
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
    },
    ...
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
console.log NL.generate()
# Override Share Repurchase for getAttrs
# Override Share Repurchase for getDifference
# Override Share Repurchase for getDisplayInfo
# Output: Share repurchase is every year.
```

#### String with custom functions + oldData
```
NL = new NaturalLanguage [{
  "title": "Share Repurchase",
  "oldData": "-",
  "newData": "Every year",
  "dataType": "sign"
}]
NL.addType "sign", { .. Same as "sign" type above .. }
console.log NL.generate()
# Override Share Repurchase for getAttrs
# Override Share Repurchase for getDifference
# Override Share Repurchase for getDisplayInfo
# Output: Share repurchase has raised from - to every year.
```

#### Use custom functions and custom sentences
```
NL = new NaturalLanguage [{
  "title": "Share Repurchase",
  "newData": "Every year",
  "dataType": "sign",
  "sentenceType": "repurchase"
}]
NL.addType "sign", { .. Same as "sign" type above .. }
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
# Override Share Repurchase for getAttrs
# Override Share Repurchase for getDifference
# Override Share Repurchase for getDisplayInfo
# Override Share Repurchase for getSimpleSentenceList
# Output: There is share repurchase every year.
```

#### Custom functions + sentences + oldData
```
NL = new NaturalLanguage [{
  "title": "Share Repurchase",
  "oldData": "Every year",
  "newData": "Every year",
  "dataType": "sign",
  "sentenceType": "repurchase"
}]
NL.addType "sign", { .. Same as "sign" type above .. }
NL.addSentence "repurchase", { .. Same as "repurchase" type above .. }
console.log NL.generate()
# Override Share Repurchase for getAttrs
# Override Share Repurchase for getDifference
# Override Share Repurchase for getDisplayInfo
# Override Share Repurchase for getSimpleSentenceList
# Output: There is still share repurchase every year.
```

#### Multiple sentences
```
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
NL.addType "sign", { .. Same as "sign" type above .. }
NL.addSentence "repurchase", { .. Same as "repurchase" type above .. }
console.log NL.generate()
# Override Share Repurchase for getAttrs
# Override Share Repurchase for getDifference
# Override Share Repurchase for getDisplayInfo
# Override Share Repurchase for getSimpleSentenceList
# Output: Growth opportunity has significantly decreased by 30 to 60 and there is still share repurchase every year.
```

#### Separate data into groups
```
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
NL.addType "sign", { .. Same as "sign" type above .. }
NL.addSentence "repurchase", { .. Same as "repurchase" type above .. }
console.log NL.generate()
# Override Share Repurchase for getAttrs
# Override Share Repurchase for getDifference
# Override Share Repurchase for getDisplayInfo
# Override Share Repurchase for getSimpleSentenceList
# Output: Growth opportunity has extremely dropped to 60. There is still share repurchase every year.
```

#### Extra example
```
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
NL.addType "sign", { .. Same as "sign" type above .. }
NL.addSentence "repurchase", { .. Same as "repurchase" type above .. }
console.log NL.generate()
# Override Share Repurchase for getAttrs
# Override Share Repurchase for getDifference
# Override Share Repurchase for getDisplayInfo
# Override Share Repurchase for getSimpleSentenceList
# Output: Growth opportunity has significantly decreased by 30 to 60 and financial strength looks good at 100. There is still share repurchase every year.
```

#### Show only two pieces of data
```
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
NL.addType "sign", { .. Same as "sign" type above .. }
NL.addSentence "repurchase", { .. Same as "repurchase" type above .. }
console.log NL.generate(2) # Put number of data to present
# Override Share Repurchase for getAttrs
# Override Share Repurchase for getDifference
# Override Share Repurchase for getDisplayInfo
# Override Share Repurchase for getSimpleSentenceList
# Output: Growth opportunity has extremely dropped to 60. There is still share repurchase every year.
```
#### Always show this data no matter what
```
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
NL.addType "sign", { .. Same as "sign" type above .. }
NL.addSentence "repurchase", { .. Same as "repurchase" type above .. }
console.log NL.generate(2) # Put number of data to present
# Override Share Repurchase for getAttrs
# Override Share Repurchase for getDifference
# Override Share Repurchase for getDisplayInfo
# Override Share Repurchase for getSimpleSentenceList
# Output: Growth opportunity has significantly decreased by 30 to 60 and financial strength is still good at 100.
```

APIs:
-----
#### Constructor:
```
NL = new NaturalLanguage(data)
```
data: array of objects, each contains the following properties, * is required
```
"title": null # (*) String: Title/name of the data
"oldData": null # Integer(default) or String: previous data to compare with current one
"newData": null # (*) Integer(default) or String: current data
"dataType": "default" # String: Type of data that can add more using addType() method
"sentenceType": "default" # String: Type of sentence that can add more using addSentence() method
"alwaysShow": false # Boolean: Always show this piece of data
"options": { # Object: Set the value of priority and level
    "priority": {
       "init": 1, # Integer: Initial priority
       "negativeFactor": 20, # Number: Rate of negative difference
       "positiveFactor": 100 # Number: Rate of positive difference
    },
    "level": {
       "threshold": 0.09, # Number: The data is considered changed if the absolute difference is more than the threshold
       "sensitiveness": 1 # Number: The data is in a difference level if newData is more different than the sensitiveness value
    }
"precision": 0 # Integer: The desired decimal length, use for display only
```

#### Add dataType
Data type can be added using addType() method
```
NL.addType: (title, func = {})
```
- **title**: name of the type
- **func**: function(s) to override

##### Functions available for overriding

1. ```getDifference(data)```
* Get the difference between old value and current value
* @param  {object}        data object (see the constructor properties)
* @return {number/string} difference value or 'na' if there is no oldData

2. ```getDisplayInfo(data)```
* Prepare strings required to show in the sentence
* @param  {object} data object (see the constructor properties)
* @return {object} information required to display in the sentence (default is ```title```, ```newData```, ```oldData```, and ```difference```)

3. ```calculatePriority(data)```
* Calculate the priority of change
* @param  {object} data object (see the constructor properties)
* @return {number} new priority

4. ```calculateLevel(data)```
* Calculate the intesity of change
* @param  {object} data object (see the constructor properties)
* @return {number} intensity of the change (from -3 to 3)

#### Add dataType
Data type can be added using addType() method
```
NL.addSentence: (title, func = {})
```
- **title**: name of the type
- **func**: function(s) to override

##### Functions available for overriding

1. ```getSimpleSentenceList(data, simpleSentencese)```
* Get a valid list of sentences for random selecting
* @param  {object} data - data object
* @param  {array}  simpleSentences - sentences from all types
* @return {array}  array of valid sentences

2. ```getCompoundSentenceList(data, compoundSentences)```
* Get a valid list of compound sentences
* @param  {object} data - data object
* @param  {array}  compoundSentences - sentences from all types
* @return {array}  array of valid sentences