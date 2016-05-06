Marty::Engine.load_seed

# Gemini seeds needed for testing purposes
Gemini::AmortizationType.create(name: "Fixed")
Gemini::AmortizationType.create(name: "Adjustable")
Gemini::MortgageType.create(name: "Conventional")
Gemini::MortgageType.create(name: "FHA")
Gemini::MortgageType.create(name: "VA")
Gemini::MortgageType.create(name: "USDA/Rural Housing")
Gemini::StreamlineType.seed

######################################################################

STATES ||=
  [
   [ "Alabama",                 "AL" ],
   [ "Alaska",                  "AK" ],
   [ "Arizona",                 "AZ" ],
   [ "Arkansas",                "AR" ],
   [ "California",              "CA" ],
   [ "Colorado",                "CO" ],
   [ "Connecticut",             "CT" ],
   [ "Delaware",                "DE" ],
   [ "District Of Columbia",    "DC" ],
   [ "Florida",                 "FL" ],
   [ "Georgia",                 "GA" ],
   [ "Hawaii",                  "HI" ],
   [ "Idaho",                   "ID" ],
   [ "Illinois",                "IL" ],
   [ "Indiana",                 "IN" ],
   [ "Iowa",                    "IA" ],
   [ "Kansas",                  "KS" ],
   [ "Kentucky",                "KY" ],
   [ "Louisiana",               "LA" ],
   [ "Maine",                   "ME" ],
   [ "Maryland",                "MD" ],
   [ "Massachusetts",           "MA" ],
   [ "Michigan",                "MI" ],
   [ "Minnesota",               "MN" ],
   [ "Mississippi",             "MS" ],
   [ "Missouri",                "MO" ],
   [ "Montana",                 "MT" ],
   [ "Nebraska",                "NE" ],
   [ "Nevada",                  "NV" ],
   [ "New Hampshire",           "NH" ],
   [ "New Jersey",              "NJ" ],
   [ "New Mexico",              "NM" ],
   [ "New York",                "NY" ],
   [ "North Carolina",          "NC" ],
   [ "North Dakota",            "ND" ],
   [ "Ohio",                    "OH" ],
   [ "Oklahoma",                "OK" ],
   [ "Oregon",                  "OR" ],
   [ "Pennsylvania",            "PA" ],
   [ "Rhode Island",            "RI" ],
   [ "South Carolina",          "SC" ],
   [ "South Dakota",            "SD" ],
   [ "Tennessee",               "TN" ],
   [ "Texas",                   "TX" ],
   [ "Utah",                    "UT" ],
   [ "Vermont",                 "VT" ],
   [ "Virginia",                "VA" ],
   [ "Washington",              "WA" ],
   [ "West Virginia",           "WV" ],
   [ "Wisconsin",               "WI" ],
   [ "Wyoming",                 "WY" ],

   # US Territories (FIXME: incomplete)
   [ "American Samoa",          "AS" ],
   [ "Guam",                    "GU" ],
   [ "Puerto Rico",             "PR" ],
   [ "Virgin Islands",          "VI" ],
  ]

STATES.each { |s| Gemini::State.create(full_name: s[0], name: s[1]) }

######################################################################