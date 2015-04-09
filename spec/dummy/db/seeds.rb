# Marty seeds needed for testing purposes
['BASE', 'CLOSE', 'INTRA', 'RULE'].each { |type|
  Marty::PostingType.create name: type
}

# Gemini seeds needed for testing purposes
Gemini::AmortizationType.create(name: "Fixed")
Gemini::AmortizationType.create(name: "Adjustable")
Gemini::MortgageType.create(name: "Conventional")
Gemini::MortgageType.create(name: "FHA")
Gemini::MortgageType.create(name: "VA")
Gemini::MortgageType.create(name: "USDA/Rural Housing")
Gemini::StreamlineType.seed
