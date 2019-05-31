require 'spec_helper'

class MammalEnum
  VALUES = Set['Dog', 'Cat', 'Human', 'Cow', 'Bear']
end

class ElectronicsEnum
  VALUES = Set['Phone', 'Keyboard', 'Terminator']
end

class NotAnEnum
  HI = 'MOM'
end

module Marty
  describe JsonSchema do
    ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
    ###                      Generic, simple data               ###
    ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

    simple_schema = {
      '$schema' => 'http://json-schema.org/marty-draft/schema#',
      'properties' => {
        'a' => {
          'type' => 'integer'
        },
      }
    }
    opt = { :validate_schema => true,
                :errors_as_objects  => false,
                :version            => Marty::JsonSchema::RAW_URI }

    it 'returns no error on correct simple data' do
      data = { 'a' => 5 }
      expect(JSON::Validator.fully_validate(simple_schema, data, opt)).to eq([])
    end

    it 'returns error on incorrect simple data -- 1' do
      data = { 'a' => 5.2 }
      expect(JSON::Validator.
              fully_validate(simple_schema, data, opt)[0]).to include(
                "property '#/a' of type number did not match the following type: integer")
    end

    it 'returns error on incorrect simple data -- 2' do
      data = { 'a' => 'Kangaroo' }
      expect(JSON::Validator.
              fully_validate(simple_schema, data, opt)[0]).to include(
                "property '#/a' of type string did not match the following type: integer")
    end

    ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
    ###                      PgEnum                             ###
    ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

    pg_schema_opt = {
      '$schema' => 'http://json-schema.org/marty-draft/schema#',
      'properties' => {
        'a' => {
          'pg_enum' => 'MammalEnum'
        },
      }
    }

    it 'returns no error on correct existing enums' do
      data = { 'a' => 'Dog' }
      expect(JSON::Validator.fully_validate(pg_schema_opt, data, opt)).to eq([])
    end

    it 'vacuously returns no error on a field not validated' do
      data = { 'b' => 'Dawg' }
      expect(JSON::Validator.fully_validate(pg_schema_opt, data, opt)).to eq([])
    end

    it 'returns error on non-existant enums' do
      data = { 'a' => 'Beer' }
      expect(JSON::Validator.
              fully_validate(pg_schema_opt, data, opt)[0]).to include(
                "property '#/a' value 'Beer' not contained in MammalEnum")
    end

    it 'returns no error when a optional field is not suppplied' do
      data = {}
      expect(JSON::Validator.fully_validate(pg_schema_opt, data, opt)).to eq([])
    end

    it 'returns error when a nil enum is passed even when enum is optional' do
      data = { 'a' => nil }
      expect(JSON::Validator.
              fully_validate(pg_schema_opt, data, opt)[0]).to include(
                "property '#/a' value '' not contained in MammalEnum")
    end

    pg_schema_req = {
      '$schema' => 'http://json-schema.org/marty-draft/schema#',
      'required' => ['a'],
      'properties' => {
        'a' => {
          'pg_enum' => 'MammalEnum'
        },
      }
    }

    it 'returns error when a required field is not supplied' do
      data = {}
      expect(JSON::Validator.
              fully_validate(pg_schema_req, data, opt)[0]).to include(
                "property '#/' did not contain a required property of 'a'")
    end

    it 'returns error when a nil enum is passed when enum is required' do
      data = { 'a' => nil }
      expect(JSON::Validator.
              fully_validate(pg_schema_req, data, opt)[0]).to include(
                "property '#/a' value '' not contained in MammalEnum")
    end

    pg_schema_req_bad = {
      '$schema' => 'http://json-schema.org/marty-draft/schema#',
      'required' => ['a'],
      'properties' => {
        'a' => {
          'pg_enum' => 'NotAnEnum'
        },
      }
    }

    it 'returns raises meaningful error on schema enum error'  do
      data = { 'a' => nil }
      expect(JSON::Validator.
              fully_validate(pg_schema_req_bad, data, opt)[0]).to include(
                "property '#/a': 'NotAnEnum' is not a pg_enum class")
    end

    pg_schema_req_bad2 = {
      '$schema' => 'http://json-schema.org/marty-draft/schema#',
      'required' => ['a'],
      'properties' => {
        'a' => {
          'pg_enum' => 'NotEvenAClass'
        },
      }
    }

    it 'returns raises meaningful error on schema enum error'  do
      data = { 'a' => nil }
      expect(JSON::Validator.
              fully_validate(pg_schema_req_bad2, data, opt)[0]).to include(
                "property '#/a': 'NotEvenAClass' is not a pg_enum class")
    end

    ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
    ###                      Date Format                        ###
    ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

    date_schema_opt = {
      '$schema' => 'http://json-schema.org/marty-draft/schema#',
      'properties' => {
        'a' => {
          'type'   => 'string',
          'format' => 'date'
        }
      }
    }

    it 'returns true on a properly formatted date' do
      data = { 'a' => '2017-05-22' }
      expect(JSON::Validator.validate(date_schema_opt, data)).to be true
    end

    it 'vacuously returns true on a field not validated' do
      data = { 'b' => 'Today is May 22nd' }
      expect(JSON::Validator.validate(date_schema_opt, data)).to be true
    end

    it 'returns error on an improperly formatted date' do
      data = { 'a' => '2017-05-32' }
      expect(JSON::Validator.
              fully_validate(date_schema_opt, data, opt)[0]).to include(
                "property '#/a' must be a date in the format of YYYY-MM-DD")
    end

    it 'returns error on an properly formatted datetime' do
      data = { 'a' => '2017-05-22T14:51:44Z' }
      expect(JSON::Validator.
              fully_validate(date_schema_opt, data, opt)[0]).to include(
                "property '#/a' must be a date in the format of YYYY-MM-DD")
    end

    it 'returns true when an optional date is not supplied' do
      data = {}
      expect(JSON::Validator.validate(date_schema_opt, data)).to be true
    end

    it 'returns error when a nil date is passed even when date is optional' do
      data = { 'a' => nil }
      expect(JSON::Validator.
              fully_validate(date_schema_opt, data, opt)[0]).to include(
                "property '#/a' of type null did not match the following type: string")
    end

    date_schema_req = {
      '$schema' => 'http://json-schema.org/marty-draft/schema#',
      'required' => ['a'],
      'properties' => {
        'a' => {
          'type'   => 'string',
          'format' => 'date'
        }
      }
    }

    it 'returns error when a required date field is not supplied' do
      data = {}
      expect(JSON::Validator.
              fully_validate(date_schema_req, data, opt)[0]).to include(
                "property '#/' did not contain a required property of 'a'")
    end

    it 'returns error when a nil date is passed when date is required' do
      data = { 'a' => nil }
      expect(JSON::Validator.
              fully_validate(date_schema_req, data, opt)[0]).to include(
                "property '#/a' of type null did not match the following type: string")
    end

    ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
    ###                      DateTime Format                    ###
    ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

    datetime_schema_opt = {
      '$schema' => 'http://json-schema.org/marty-draft/schema#',
      'properties' => {
        'a' => {
          'type'   => 'string',
          'format' => 'date-time'
        }
      }
    }

    it 'returns true on a properly formatted datetime' do
      data = { 'a' => '2017-05-22T14:51:44Z' }
      expect(JSON::Validator.validate(datetime_schema_opt, data)).to be true
    end

    it 'vacuously returns true on a field not validated' do
      data = { 'b' => 'Today is May 22nd' }
      expect(JSON::Validator.validate(datetime_schema_opt, data)).to be true
    end

    it 'returns error on an improperly formatted datetime' do
      data = { 'a' => '2017-30-22T14:51:44Z' }
      expect(JSON::Validator.
              fully_validate(datetime_schema_opt, data, opt)[0]).to include(
                "property '#/a' must be a date/time in the ISO-8601 format")
    end

    it 'returns true when an opt field is not supplied' do
      data = {}
      expect(JSON::Validator.validate(datetime_schema_opt, data)).to be true
    end

    it 'returns error when a nil dt is passed even when dt is opt' do
      data = { 'a' => nil }
      expect(JSON::Validator.
              fully_validate(datetime_schema_opt, data, opt)[0]).to include(
                "property '#/a' of type null did not match the following type: string")
    end

    datetime_schema_req = {
      '$schema' => 'http://json-schema.org/marty-draft/schema#',
      'required' => ['a'],
      'properties' => {
        'a' => {
          'type'   => 'string',
          'format' => 'date-time'
        }
      }
    }

    it 'returns error when a required field is not supplied' do
      data = {}
      expect(JSON::Validator.
              fully_validate(datetime_schema_req, data, opt)[0]).to include(
                "property '#/' did not contain a required property of 'a'")
    end

    it 'returns error when a nil dt is passed when dt is required' do
      data = { 'a' => nil }
      expect(JSON::Validator.
              fully_validate(datetime_schema_req, data, opt)[0]).to include(
                "property '#/a' of type null did not match the following type: string")
    end

    ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
    ###                 PgEnum & DateTime Format                ###
    ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

    pg_dt_schema = {
      '$schema' => 'http://json-schema.org/marty-draft/schema#',
      'properties' => {
        'a' => {
          'pg_enum' => 'MammalEnum'
        },
        'b' => {
          'type'   => 'string',
          'format' => 'date-time'
        },
      }
    }

    it 'validates both pg_enum and dt format when both are correct' do
      data = { 'a' => 'Dog', 'b' => '2017-05-22T14:51:44Z' }
      expect(JSON::Validator.validate(pg_dt_schema, data)).to be true
    end

    it 'validates both pg_enum and dt format when only enum is correct' do
      data = { 'a' => 'Dog', 'b' => '2017-55-22T14:51:44Z' }
      expect(JSON::Validator.validate(pg_dt_schema, data)).to be false
    end

    it 'validates both pg_enum and dt format when only dt is correct' do
      data = { 'a' => 'Dogg', 'b' => '2017-05-22T14:51:44Z' }
      expect(JSON::Validator.validate(pg_dt_schema, data)).to be false
    end

    it 'validates both pg_enum and dt format when neither is correct' do
      data = { 'a' => 'Dogg', 'b' => '2017-55-22T14:51:44Z' }
      expect(JSON::Validator.validate(pg_dt_schema, data)).to be false
    end

    pg_dt_int_schema = {
      '$schema' => 'http://json-schema.org/marty-draft/schema#',
      'properties' => {
        'a' => {
          'pg_enum' => 'MammalEnum'
        },
        'b' => {
          'type'   => 'string',
          'format' => 'date-time'
        },
        'c' => {
          'type' => 'integer'
        },
      }
    }

    it 'validates pg_enum, dt format and int when they are correct' do
      data = { 'a' => 'Dog', 'b' => '2017-05-22T14:51:44Z', 'c' => 5 }
      expect(JSON::Validator.validate(pg_dt_int_schema, data)).to be true
    end

    it 'validates pg_enum, dt format and int when one is incorrect' do
      data = { 'a' => 'Chair', 'b' => '2017-05-22T14:51:44Z', 'c' => 5 }
      expect(JSON::Validator.validate(pg_dt_int_schema, data)).to be false
    end

    pg_dt_int_schema_req = {
      '$schema' => 'http://json-schema.org/marty-draft/schema#',
      'required' => ['b'],
      'properties' => {
        'a' => {
          'pg_enum' => 'MammalEnum'
        },
        'b' => {
          'type'   => 'string',
          'format' => 'date-time'
        },
        'c' => {
          'type' => 'integer'
        },
      }
    }

    it 'validates pg_enum, dt format and int when dt is required' do
      data = { 'a' => 'Dog', 'd' => '2017-05-22T14:51:44Z', 'c' => 5 }
      expect(JSON::Validator.validate(pg_dt_int_schema_req, data)).to be false
    end

    pg_dt_pg_int_schema = {
      '$schema' => 'http://json-schema.org/marty-draft/schema#',
      'required' => ['c'],
      'properties' => {
        'a' => {
          'pg_enum' => 'MammalEnum'
        },
        'b' => {
          'type'   => 'string',
          'format' => 'date-time'
        },
        'c' => {
          'pg_enum' => 'ElectronicsEnum'
        },
        'd' => {
          'type' => 'integer'
        },
      }
    }

    it 'validates a schema containing 2 pg_enums, one that is required' do
      data = { 'a' => 'Dog',
               'b' => '2017-05-22T14:51:44Z',
               'c' => 'Phone',
               'd' => 5 }
      expect(JSON::Validator.validate(pg_dt_pg_int_schema, data)).to be true
    end

    it 'validates a schema containing 2 pg_enums, one that is required' do
      data = { 'a' => 'Dog',
               'b' => '2017-05-22T14:51:44Z',
               'e' => 'Phone',
               'd' => 5 }
      expect(JSON::Validator.validate(pg_dt_pg_int_schema, data)).to be false
    end

    ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
    ###                      Nested Schemas                     ###
    ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

    nested_schema = {
      '$schema' => 'http://json-schema.org/marty-draft/schema#',
      'required' => ['a', 'b', 'c', 'd', 'root1', 'root2'],
      'properties' => {
        'a' => {
          'pg_enum' => 'MammalEnum'
        },
        'b' => {
          'type'   => 'string',
          'format' => 'date-time'
        },
        'c' => {
          'pg_enum' => 'ElectronicsEnum'
        },
        'd' => {
          'type' => 'integer'
        },
        'root1' => {
          'type' => 'array',
          'minItems' => 3,
          'items' => {
            'required' => ['x', 'y'],
            'properties' => {
              'x' => { 'type' => 'object',
                       'required' => ['w', 't', 'f'],
                       'properties' => { 'w' => { 'type'       => 'integer',
                                                  'minimum'    => 0,
                                                  'maximum'    => 3           },
                                         't' => { 'pg_enum'    => 'MammalEnum' },
                                         'f' => { 'type'       => ['number'],
                                                  'minimum'    => 0,
                                                  'maximum'    => 100,
                                                  'multipleOf' => 5.0           } }
                     },
              'y' => { 'pg_enum' => 'ElectronicsEnum' }
            }
          }
        },
        'root2' => {
          'type' => 'array',
          'minItems' => 2,
          'items' => {
            'required' => ['m1', 'e', 'm2'],
            'properties' => {
              'm1' => { 'pg_enum' => 'MammalEnum'      },
              'e' =>  { 'pg_enum' => 'ElectronicsEnum' },
              'm2' => { 'pg_enum' => 'MammalEnum'      },
            }
          },
        },
      }
    }

    it 'validates a complex nested schema when correct' do
      data = { 'a' => 'Dog',
               'b' => '2017-05-22T14:51:44Z',
               'root1' => [{ 'x' => { 'w' => 0, 't' => 'Bear',  'f' => 0.0 },
                              'y' => 'Phone' },
                           { 'x' => { 'w' => 1, 't' => 'Human', 'f' => 5.0 },
                             'y' => 'Terminator' },
                           { 'x' => { 'w' => 2, 't' => 'Dog',   'f' => 65.0 },
                             'y' => 'Phone' }],
               'root2' => [{ 'm1' => 'Cat', 'e' => 'Keyboard', 'm2' => 'Dog' },
                           { 'm1' => 'Dog', 'e' => 'Phone',    'm2' => 'Cow' }],
               'c' => 'Terminator',
               'd' => 5
             }
      expect(JSON::Validator.validate(nested_schema, data)).to be true
    end

    it 'validates a complex nested schema when incorrect -- 1' do
      data = { 'a' => 'Dog',
               'b' => '2017-05-32T14:51:44Z', # note DD
               'root1' => [{ 'x' => { 'w' => 0, 't' => 'Bear',  'f' => 0.0 },
                              'y' => 'Phone' },
                           { 'x' => { 'w' => 1, 't' => 'Human', 'f' => 5.0 },
                             'y' => 'Terminator' },
                           { 'x' => { 'w' => 2, 't' => 'Dog',   'f' => 65.0 },
                             'y' => 'Phone' }],
               'root2' => [{ 'm1' => 'Cat', 'e' => 'Keyboard', 'm2' => 'Dog' },
                           { 'm1' => 'Dog', 'e' => 'Phone',    'm2' => 'Cow' }],
               'c' => 'Terminator',
               'd' => 5
             }
      expect(JSON::Validator.validate(nested_schema, data)).to be false
    end

    it 'validates a complex nested schema when incorrect -- 2' do
      data = { 'a' => 'Dog',
               'b' => '2017-05-22T14:51:44Z',
               'root1' => [{ 'x' => { 'w' => 0, 't' => 'Bar',   'f' => 0.0 },
                              'y' => 'Phone' },
                           { 'x' => { 'w' => 1, 't' => 'Human', 'f' => 5 },
                             'y' => 'Terminator' },
                           { 'x' => { 'w' => 2, 't' => 'Dog',   'f' => 65.0 },
                             'y' => 'Phone' }],
               'root2' => [{ 'm1' => 'Cat', 'e' => 'Keyboard', 'm2' => 'Dog' },
                           { 'm1' => 'Dog', 'e' => 'Phone',    'm2' => 'Cow' }],
               'c' => 'Terminator',
               'd' => 5
             }
      expect(JSON::Validator.
              fully_validate(nested_schema, data, opt)[0]).to include(
                "property '#/root1/0/x/t' value 'Bar' not contained in MammalEnum")
    end

    it 'validates a complex nested schema when incorrect -- 3' do
      data = { 'a' => 'Dog',
               'b' => '2017-05-22T14:51:44Z',
               'root1' => [{ 'x' => { 'w' => 0, 't' => 'Bear',  'f' => 0.0 },
                              'y' => 'Phone' },
                           { 'x' => { 'w' => 1, 't' => 'Human', 'f' => 6.0 },
                             'y' => 'Terminator' },
                           { 'x' => { 'w' => 2, 't' => 'Dog',   'f' => 65.0 },
                             'y' => 'Phone' }],
               'root2' => [{ 'm1' => 'Cat', 'e' => 'Keyboard', 'm2' => 'Dog' },
                           { 'm1' => 'Dog', 'e' => 'Phone',    'm2' => 'Cow' }],
               'c' => 'Terminator',
               'd' => 5
             }
      expect(JSON::Validator.
              fully_validate(nested_schema, data, opt)[0]).to include(
                "property '#/root1/1/x/f' was not divisible by 5.0")
    end

    it 'validates a complex nested schema when incorrect -- 4' do
      data = { 'a' => 'Dog',
               'b' => '2017-05-22T14:51:44Z',
               'root1' => [{ 'x' => { 'w' => 0, 't' => 'Bear',  'f' => 0.0 },
                              'y' => 'Phone' },
                           { 'x' => { 'w' => 1, 't' => 'Human', 'f' => 5.0 },
                             'y' => 'Trminator' },
                           { 'x' => { 'w' => 2, 't' => 'Dog',   'f' => 65.0 },
                             'y' => 'Phone' }],
               'root2' => [{ 'm1' => 'Cat', 'e' => 'Keyboard', 'm2' => 'Dog' },
                           { 'm1' => 'Dog', 'e' => 'Phone',    'm2' => 'Cow' }],
               'c' => 'Terminator',
               'd' => 5
             }
      expect(JSON::Validator.
              fully_validate(nested_schema, data, opt)[0]).to include(
                "property '#/root1/1/y' value 'Trminator' not contained "\
                'in ElectronicsEnum')
    end

    it 'validates a complex nested schema when incorrect -- 5' do
      data = { 'a' => 'Dog',
               'b' => '2017-05-22T14:51:44Z',
               'root1' => [{ 'x' => { 'w' => 0, 't' => 'Bear',  'f' => 0.0 },
                              'y' => 'Phone' },
                           { 'x' => { 'w' => 1, 't' => 'Human', 'f' => 5.0 },
                             'y' => 'Terminator' },
                           { 'x' => { 'w' => 5, 't' => 'Dog',   'f' => 65.0 },
                             'y' => 'Phone' }],
               'root2' => [{ 'm1' => 'Cat', 'e' => 'Keyboard', 'm2' => 'Dog' },
                           { 'm1' => 'Dog', 'e' => 'Phone',    'm2' => 'Cow' }],
               'c' => 'Terminator',
               'd' => 5
             }
      expect(JSON::Validator.
              fully_validate(nested_schema, data, opt)[0]).to include(
                "property '#/root1/2/x/w' did not have a maximum value of 3, inclusively")
    end

    it 'validates a complex nested schema when incorrect -- 6' do
      data = { 'a' => 'Dog',
               'b' => '2017-05-22T14:51:44Z',
               'root1' => [{ 'x' => { 'w' => 0, 't' => 'Bear',  'f' => 0.0 },
                              'y' => 'Phone' },
                           { 'x' => { 'w' => 1, 't' => 'Human', 'f' => 5.0 },
                             'y' => 'Terminator' },
                           { 'x' => { 'w' => -5, 't' => 'Dog',   'f' => 65.0 },
                             'y' => 'Phone' }],
               'root2' => [{ 'm1' => 'Cat', 'e' => 'Keyboard', 'm2' => 'Dog' },
                           { 'm1' => 'Dog', 'e' => 'Phone',    'm2' => 'Cow' }],
               'c' => 'Terminator',
               'd' => 5
             }
      expect(JSON::Validator.
              fully_validate(nested_schema, data, opt)[0]).to include(
                "property '#/root1/2/x/w' did not have a minimum value of 0, inclusively")
    end

    it 'validates a complex nested schema when incorrect -- 7' do
      data = { 'a' => 'Dog',
               'b' => '2017-05-22T14:51:44Z',
               'root1' => [{ 'x' => { 'w' => 0, 't' => 'Bear',  'f' => 0.0 },
                              'y' => 'Phone' },
                           { 'x' => { 'w' => 1, 't' => 'Human', 'f' => 5.0 },
                             'y' => 'Terminator' },
                           { 'x' => { 'w' => 2, 't' => 'Dog',   'f' => 65.0 },
                             'y' => 'Phone' }],
               'root2' => [{ 'm1' => 'Cat', 'e' => 'Keyboard', 'm2' => 'Dog' },
                           { 'm1' => 'Dog', 'e' => 'Dog',    'm2' => 'Cow' }],
               'c' => 'Terminator',
               'd' => 5
             }
      expect(JSON::Validator.
              fully_validate(nested_schema, data, opt)[0]).to include(
                "property '#/root2/1/e' value 'Dog' not contained in ElectronicsEnum")
    end
  end

  ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
  ###                      URI                                ###
  ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###

  class FloorOf8 < JSON::Schema::Attribute
    def self.validate(curr_schema, data, frag, processor, _validator, opt)
      if data < 8
        msg = 'Error at FloorOf8: Value is below 8'
        validation_error(processor,
                         msg,
                         frag,
                         curr_schema,
                         self,
                         opt[:record_errors])
      end
    end
  end

  class CeilingOf20 < JSON::Schema::Attribute
    def self.validate(curr_schema, data, frag, processor, _validator, opt)
      if data > 20
        msg = 'Error at CeilingOf20: Value exceeds 20'
        validation_error(processor,
                         msg,
                         frag,
                         curr_schema,
                         self,
                         opt[:record_errors])
      end
    end
  end

  describe 'how @uri behaves as a key to a set of attributes' do
    class BoundSchema < JSON::Schema::Draft4
      def initialize
        super
        @attributes['bound'] = CeilingOf20
        uri = 'http://json-schema.org/bound-draft/schema#'
        @uri = JSON::Util::URI.parse(uri)
      end

      JSON::Validator.register_validator(new)
    end

    marty_uri = {
     '$schema' => 'http://json-schema.org/marty-draft/schema#',
      'required'    => ['a'],
      'properties'  => {
        'a' => {
          'pg_enum'    => 'MammalEnum',
        },
      }
    }

    bound_uri = {
      '$schema' => 'http://json-schema.org/bound-draft/schema#',
      'required'    => ['a'],
      'properties'  => {
        'a' => {
          'pg_enum'    => 'MammalEnum',
        },
      }
    }

    it 'validates an attribute dictated by its uri (Positive)' do
      data = { 'a' => 'Dog' }
      expect(JSON::Validator.validate(marty_uri, data)).to be true
    end

    it 'validates an attribute dictated by its uri (Negative)' do
      data = { 'a' => 'Table' }
      expect(JSON::Validator.validate(marty_uri, data)).to be false
    end

    it 'incorrectly validates an attribute not part of its uri' do
      data = { 'a' => 'Table' }
      expect(JSON::Validator.validate(bound_uri, data)).to be true
    end
  end

  describe 'how @uri also behaves as namespace' do
    class BoundFloorSchema < JSON::Schema::Draft4
      def initialize
        super
        @attributes['bound'] = FloorOf8
        uri = 'http://json-schema.org/bound-floor-draft/schema#'
        @uri = JSON::Util::URI.parse(uri)
      end

      JSON::Validator.register_validator(new)
    end

    class BoundCeilingSchema < JSON::Schema::Draft4
      def initialize
        super
        @attributes['bound'] = CeilingOf20
        uri = 'http://json-schema.org/bound-ceiling-draft/schema#'
        @uri = JSON::Util::URI.parse(uri)
      end

      JSON::Validator.register_validator(new)
    end

    bound_floor_schema = {
     '$schema' => 'http://json-schema.org/bound-floor-draft/schema#',
      'required'    => ['a'],
      'properties'  => {
        'a' => {
          'bound'    => '',
        },
      }
    }

    bound_ceiling_schema = {
     '$schema' => 'http://json-schema.org/bound-ceiling-draft/schema#',
      'required'    => ['a'],
      'properties'  => {
        'a' => {
          'bound'    => '',
        },
      }
    }

    it 'validates BoundFloorSchema when called with its uri (Positive)' do
      data = { 'a' => 9 }
      expect(JSON::Validator.validate(bound_floor_schema, data)).to be true
    end

    it 'validates BoundFloorSchema when called with its uri (Negative)' do
      data = { 'a' => 7 }
      expect(JSON::Validator.validate(bound_floor_schema, data)).to be false
    end

    it 'validates BoundCeilingSchema when called with its uri (Positive)' do
      data = { 'a' => 19 }
      expect(JSON::Validator.validate(bound_ceiling_schema, data)).to be true
    end

    it 'validates BoundCielingSchema when called with its uri (Negative)' do
      data = { 'a' => 21 }
      expect(JSON::Validator.validate(bound_ceiling_schema, data)).to be false
    end
  end
end
