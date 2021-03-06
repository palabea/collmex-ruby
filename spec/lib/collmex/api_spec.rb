require "spec_helper"

sample_spec = [  
          { name: :identifier , type: :string   , fix: "BLA" },
          { name: :b          , type: :currency              },
          { name: :c          , type: :float                 },
          { name: :d          , type: :integer               },
          { name: :e          , type: :date                  },
]

empty_hash = { identifier: "BLA", b: nil, c: nil, d: nil, e: nil }

empty_array = ["BLA", nil, nil, nil, nil]

filled_array = ["BLA", 20, 5.1, 10, Date.parse("12.10.1985")]

filled_csv   = "BLA;0,20;5,10;10;19851012\n"

describe Collmex::Api do

  describe ".is_a_collmex_api_line_obj?" do
    it "should fail for an array" do
      a = Array.new
      described_class.is_a_collmex_api_line_obj?(a).should be_false
    end

    it "should succeed for a Collmex::Api Object" do
      b = Collmex::Api::AccdocGet.new() 
      described_class.is_a_collmex_api_line_obj?(b).should be_true
    end
  end

  describe ".line_class_exists?" do
    it "should be true for a existing class" do
      Collmex::Api.line_class_exists?("Line").should be true
    end

    it "should be false for a non existant class" do
      Collmex::Api.line_class_exists?("asdasdasdasdaaBla").should be false
    end
  end

  describe ".stringify_field" do
    tests = [
              { type: :string,      input: "asd",             outcome: "asd" },
              { type: :string,      input: "",                outcome: "" },
              { type: :string,      input: nil,               outcome: "" },

              { type: :integer,     input: nil,               outcome: "" },
              { type: :integer,     input: 2,                 outcome: "2" },
              { type: :integer,     input: 2.2,               outcome: "2" },
              { type: :integer,     input: -2.2,              outcome: "-2" },
              { type: :integer,     input: "-2.2",            outcome: "-2" },

              { type: :float,       input: 2.2,               outcome: "2,20" },
              { type: :float,       input: 2,                 outcome: "2,00" },
              { type: :float,       input: "2",               outcome: "2,00" },
              { type: :float,       input: "-2.00",           outcome: "-2,00" },
              { type: :float,       input: -2.00,             outcome: "-2,00" },

              { type: :currency,    input: 2,                 outcome: "0,02" },
              { type: :currency,    input: "2",               outcome: "0,02" },
              { type: :currency,    input: "-2.23",           outcome: "-2,23" },   # <= WARNING
              { type: :currency,    input: "-2,23",           outcome: "-2,23" },   # <= WARNING
              { type: :currency,    input: -2.00,             outcome: "-2,00" },
              { type: :currency,    input: -2.90,             outcome: "-2,90" },
              { type: :currency,    input: -2.999,             outcome: "-3,00" },
              { type: :currency,    input: -102.90,           outcome: "-102,90" },    # <= WARNING


    ]
    tests.each do |test|
      it "should represent #{test[:type]} \"#{test[:input].inspect}\" as \"#{test[:outcome]}\"" do
        described_class.stringify(test[:input],test[:type]).should === test[:outcome]
      end
    end
  end

  describe ".parse_line" do
    context "when given a valid line" do
      context "as an array" do
        it "should instanciate an api line object" do
          line = Collmex::Api::Login.new([12,34]).to_a
          described_class.parse_line(line).should be_a Collmex::Api::Line
        end
      end
      context "as n csv string" do
        it "should instanciate an api line object" do
          line = Collmex::Api::Login.new([12,34]).to_csv
          described_class.parse_line(line).should be_a Collmex::Api::Line
        end
      end
    end

    context "when given an invalid line" do
      it "should throw an error" do
        line = ["OMG", 2,3,4,5,6]
        lambda { described_class.parse_line(line) }.should raise_error 'Could not find a Collmex::Api::Line class for "Omg"'
      end
    end
  end

  describe ".parse_field" do
    tests = [
              { type: :string,      input: "asd",             outcome: "asd" },
              { type: :string,      input: "2",               outcome: "2" },
              { type: :string,      input: "2",               outcome: "2" },
              { type: :string,      input: 2,                 outcome: "2" },
              { type: :string,      input: "-2.3",            outcome: "-2.3" },
              { type: :string,      input:  nil,              outcome: "" },

              { type: :date,        input: nil,               outcome: nil },
              { type: :date,        input: "19851012",        outcome: Date.parse("12.10.1985") },
              { type: :date,        input: "1985/10/12",      outcome: Date.parse("12.10.1985") },
              { type: :date,        input: "1985-10-12",      outcome: Date.parse("12.10.1985") },


              { type: :integer,     input: "2,3",             outcome: 2 },          # <= WARNING
              { type: :integer,     input: "2",               outcome: 2 },
              { type: :integer,     input: "2.2",             outcome: 2 },
              { type: :integer,     input: 2,                 outcome: 2 },
              { type: :integer,     input: 2.2,               outcome: 2 },
              { type: :integer,     input: nil,               outcome: nil },          # <= WARNING

              { type: :float,       input: "2",               outcome: 2.0 },
              { type: :float,       input: 2,                 outcome: 2.0 },
              { type: :float,       input: "2,0",             outcome: 2.0 },
              { type: :float,       input: "2.0",             outcome: 2.0 },
              { type: :float,       input: 2.0,               outcome: 2.0 },
              { type: :float,       input: "2.2",             outcome: 2.2 },
              { type: :float,       input: 2.2,               outcome: 2.2 },
              { type: :float,       input: "2,3",             outcome: 2.3 },
              { type: :float,       input: "-2,3",            outcome: -2.3 },
              { type: :float,       input: nil,               outcome: nil },

              { type: :currency,    input: "2",               outcome: 2 },
              { type: :currency,    input: 0,                 outcome: 0 },
              { type: :currency,    input: 2,                 outcome: 2 },
              { type: :currency,    input: 2.20,              outcome: 220 },
              { type: :currency,    input: "0",               outcome: 0 },
              { type: :currency,    input: "0000",            outcome: 0 },
              { type: :currency,    input: "2,0",             outcome: 200 },
              { type: :currency,    input: "2,1",             outcome: 210 },
              { type: :currency,    input: "-2,1",            outcome: -210 },
              { type: :currency,    input: "-2.1",            outcome: -210 },
              { type: :currency,    input: "20,00",           outcome: 2000 },
              { type: :currency,    input: "20,12",           outcome: 2012 },
              { type: :currency,    input: "-20,12",          outcome: -2012 },
              { type: :currency,    input: nil,               outcome: nil },
              { type: :currency,    input: "-20.12",          outcome: -2012 },
              { type: :currency,    input: "-20.",            outcome: -2000 },
              { type: :currency,    input: "20.",             outcome: 2000 },
              { type: :currency,    input: ".20",             outcome: 20 },
              { type: :currency,    input: "-,20",            outcome: -20 },
              { type: :currency,    input: ",20",             outcome: 20 },

              { type: :currency,    input: "20,000",          outcome: 2000000 },
              { type: :currency,    input: "123,456",         outcome: 12345600 },
              { type: :currency,    input: "123,456,789",     outcome: 12345678900 },
              { type: :currency,    input: "123.456.789",     outcome: 12345678900 },
              { type: :currency,    input: "23.456.789",      outcome: 2345678900 },
              { type: :currency,    input: "-23.456.000",     outcome: -2345600000},
              { type: :currency,    input: "-23,456,000",     outcome: -2345600000 },

              { type: :currency,    input: "-23,456.00",      outcome: -2345600 },
              { type: :currency,    input: "23,456.13",       outcome: 2345613 },

              { type: :currency,    input: "21,000",          outcome: 2100000 },
              { type: :currency,    input: "12.345,20",       outcome: 1234520 },

            ]
    tests.each_with_index do |t,i|
      it "should parse #{t[:type]} value for \"#{t[:input]}\"" do
        described_class.parse_field( t[:input], t[:type]).should === t[:outcome]
      end
    end
  end
end

shared_examples_for "Collmex Api Command" do

  describe ".hashify" do
  
    it "should parse the fields" do
      string    = "BLA"
      integer   = 421 
      float     = 123.23
      currency  = 200
      date      = Date.parse("12.10.1985")

      output = { identifier: string, b: currency, c: float, d: integer, e: Date.parse("12.10.1985") }

      described_class.stub(:specification).and_return(sample_spec)
      Collmex::Api.stub(:parse_field).with(anything(),:string).and_return string
      Collmex::Api.stub(:parse_field).with(anything(),:float).and_return float
      Collmex::Api.stub(:parse_field).with(anything(),:integer).and_return integer
      Collmex::Api.stub(:parse_field).with(anything(),:currency).and_return currency
      Collmex::Api.stub(:parse_field).with(anything(),:date).and_return date

      tests = [
                  [1,2,3,4],          
                  [1,nil,3],     
                  [1],          
                  {a: 1, b:nil}, 
                  {},           
                  {c: 3},        
                  "1;2;3",       
                  "1;-2;3",      
                  "1;-2,5;3",  
                  ";;3",         
      ]

      tests.each do |testdata|
        described_class.hashify(testdata).should eql output
      end
    end

    it "should set default values when nothing given" do
      sample_default_spec = [  
                        { name: :a,       type: :string,      default: "fixvalue" },
                        { name: :b,       type: :currency,    default: 899 },
                        { name: :c,       type: :integer,     default: 10 },
                        { name: :d,       type: :float,       default: 2.99 },
                    ] 
      sample_default_outcome = {a: "fixvalue", b: 899, c: 10, d: 2.99}
      described_class.stub(:specification).and_return sample_default_spec
      described_class.hashify([]).should eql sample_default_outcome
    end

    it "should overwrite default values when data is given" do
      sample_default_spec = [  
                        { name: :a,       type: :string,      default: "fixvalue" },
                        { name: :b,       type: :currency,    default: 899 },
                        { name: :c,       type: :integer,     default: 10 },
                        { name: :d,       type: :float,       default: 2.99 },
                    ] 
      sample_default_outcome = {a: "asd", b: 12, c: 1, d: 1.0}
      described_class.stub(:specification).and_return sample_default_spec
      described_class.hashify({a: "asd", b: 12, c: 1, d: 1}).should eql sample_default_outcome
    end

    it "should ignore given values for fix-value-fields" do
      sample_fix_spec = [  
                        { name: :a,       type: :string,      fix: "fixvalue" },
                        { name: :b,       type: :currency,    fix: 899 },
                        { name: :c,       type: :integer,     fix: 10 },
                        { name: :d,       type: :float,       fix: 2.99 },
                    ] 
      sample_fix_outcome = {a: "fixvalue", b: 899, c: 10, d: 2.99}
      described_class.stub(:specification).and_return sample_fix_spec
      described_class.hashify([]).should eql sample_fix_outcome
    end
  end

  describe ".default_hash" do
    it "should hold a specification" do
      described_class.stub(:specification).and_return([])
      described_class.default_hash.should eql({})

      described_class.stub(:specification).and_return(sample_spec)
      described_class.default_hash.should eql(empty_hash)
    end
  end

  subject { described_class.new }

  it { should respond_to :to_csv }
  it { should respond_to :to_a }
  it { should respond_to :to_s }
  it { should respond_to :to_h }

  describe "#initialize" do
    it "should raise an error if the specification is empty and the class is not Collmex::Api::Line" do
      described_class.stub(:specification).and_return({})
      if described_class.name == "Collmex::Api::Line"
        lambda { described_class.new }.should_not raise_error
      else
        lambda { described_class.new }.should raise_error "#{described_class.name} has no specification"
      end
    end

    it "should set the instance_variable hash" do
      subject.instance_variable_get(:@hash).should be_a Hash
    end

    context "no params given" do
      it "should build the specified but empty hash" do
        described_class.stub(:default_hash).and_return(empty_hash)
        line = described_class.new
        line.to_h.should eql(empty_hash)
      end
    end

    context "something given" do
      it "should build the specified and filled hash" do
        input = { a: "bla" }
        output = empty_hash.merge(input)

        described_class.stub(:default_hash).and_return(empty_hash)
        described_class.stub(:hashify).and_return(output)
        line = described_class.new(input)
        line.to_h.should eql (output)
      end
    end
  end

  describe "#to_csv" do
    it "should represent the request as csv" do
      described_class.stub(:specification).and_return(sample_spec)
      subject.instance_variable_set(:@hash, described_class.hashify(filled_array))
      subject.to_csv.should eql filled_csv
    end
  end

  describe "#to_h" do
    it "should return the hash" do 
      h = { first: 1, second: 2 }
      subject.instance_variable_set(:@hash, h)
      subject.to_h.should eql h
    end
  end

  describe "#to_a" do
    it "should return the empty_hash translated to an array" do
      described_class.stub(:specification).and_return(sample_spec)
      subject.to_a.should eql empty_array
    end
  end


end

describe Collmex::Api::Adrgrp do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_adressgruppen
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier  , type: :string  , fix: "ADRGRP" },
          { name: :id          , type: :integer                 },
          { name: :description , type: :string                  }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1} ) }

  output = ["ADRGRP", 1, ""]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::AboGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Periodische_rechnung
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier         , type: :string  , fix: "ABO_GET" },
          { name: :customer_id        , type: :integer                  },
          { name: :company_id         , type: :integer , default: 1     },
          { name: :product_id         , type: :string                   },
          { name: :next_invoice_from  , type: :date                     },
          { name: :next_invoice_to    , type: :date                     },
          { name: :only_valid         , type: :integer                  },
          { name: :only_changed       , type: :integer                  },
          { name: :system_name        , type: :string                   }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {customer_id: 9999} ) }

  output = ["ABO_GET", 9999, 1, "", nil, nil, nil, nil, ""]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::Accdoc do   # fixme ACCDOC # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Buchhaltungsbelege
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier        , type: :string  , fix: "ACCDOC" },
          { name: :company_id        , type: :integer , default: 1    },
          { name: :business_year     , type: :integer                 },
          { name: :id                , type: :integer                 },
          { name: :date              , type: :date                    },
          { name: :accounted_date    , type: :date                    },
          { name: :test              , type: :string                  },
          { name: :position_id       , type: :integer                 },
          { name: :account_id        , type: :integer                 },
          { name: :account_name      , type: :string                  },
          { name: :should_have       , type: :integer                 },
          { name: :amount            , type: :currency                },
          { name: :customer_id       , type: :integer                 },
          { name: :customer_name     , type: :string                  },
          { name: :provider_id       , type: :integer                 },
          { name: :provider_name     , type: :string                  },
          { name: :asset_id          , type: :integer                 },
          { name: :asset_name        , type: :string                  },
          { name: :canceled_accdoc   , type: :integer                 },
          { name: :cost_center       , type: :string                  },
          { name: :invoice_id        , type: :string                  },
          { name: :customer_order_id , type: :integer                 },
          { name: :journey_id        , type: :integer                 },
          { name: :belongs_to_id     , type: :integer                 },
          { name: :belongs_to_year   , type: :integer                 },
          { name: :belongs_to_pos    , type: :integer                 }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1, customer_id: 9999} ) }

  output = ["ACCDOC", 1, nil, 1, nil, nil, "", nil, nil, "", nil, nil, 9999, "", nil, "", nil, "", nil, "", "", nil, nil, nil, nil, nil]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::AccdocGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Buchhaltungsbelege
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier    , type: :string  , fix: "ACCDOC_GET" },
          { name: :company_id    , type: :integer , default: 1        },
          { name: :business_year , type: :integer                     },
          { name: :id            , type: :integer                     },
          { name: :account_id    , type: :integer                     },
          { name: :cost_unit     , type: :integer                     },
          { name: :customer_id   , type: :integer                     },
          { name: :provider_id   , type: :integer                     },
          { name: :asset_id      , type: :integer                     },
          { name: :invoice_id    , type: :integer                     },
          { name: :journey_id    , type: :integer                     },
          { name: :text          , type: :string                      },
          { name: :date_start    , type: :date                        },
          { name: :date_end      , type: :date                        },
          { name: :cancellation  , type: :integer                     },
          { name: :changed_only  , type: :integer                     },
          { name: :system_name   , type: :string                      }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1, customer_id: 9999} ) }

  output = ["ACCDOC_GET", 1, nil, 1, nil, nil, 9999, nil, nil, nil, nil, "", nil, nil, nil, nil, ""]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::AddressGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Adressen
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier       , type: :string  , fix: "ADDRESS_GET" },
          { name: :id               , type: :integer                      },
          { name: :type             , type: :integer                      },
          { name: :text             , type: :string                       },
          { name: :due_to_review    , type: :integer                      },
          { name: :zipcode          , type: :string                       },
          { name: :address_group_id , type: :integer                      },
          { name: :changed_only     , type: :integer                      },
          { name: :system_name      , type: :string                       },
          { name: :contact_id       , type: :integer                      }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1} ) }

  output = ["ADDRESS_GET", 1, nil, "", nil, "", nil, nil, "", nil]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::AddressGroupsGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Adressgruppen
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier , type: :string , fix: "ADDRESS_GROUPS_GET" }
      ]

  specify { described_class.specification.should eql spec }

  output = ["ADDRESS_GROUPS_GET"]

  specify { subject.to_a.should eql output }
end

#describe Collmex::Api::BillOfMaterialGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Stuecklisten
  # tbd
#end

describe Collmex::Api::Cmxabo do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_periodische_rechnung
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier          , type: :string  , fix: "ABO_GET" },
          { name: :customer_id         , type: :integer                  },
          { name: :company_id          , type: :integer , default: 1     },
          { name: :valid_from          , type: :date                     },
          { name: :valid_to            , type: :date                     },
          { name: :product_id          , type: :string                   },
          { name: :product_description , type: :string                   },
          { name: :customized_price    , type: :currency                 },
          { name: :interval            , type: :integer                  },
          { name: :next_invoice        , type: :date                     }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {customer_id: 9999} ) }

  output = ["ABO_GET", 9999, 1, nil, nil, "", "", nil, nil, nil]

  specify { subject.to_a.should eql output }
end

#describe Collmex::Api::Cmxact do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_taetigkeiten
  # tbd
#end

describe Collmex::Api::Cmxadr do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_adressen
  it_behaves_like "Collmex Api Command"
  spec =
      [
          { name: :identifier          , type: :string  , fix: "CMXADR" },
          { name: :id                  , type: :integer                 },
          { name: :type                , type: :integer                 },
          { name: :salutation          , type: :string                  },
          { name: :title               , type: :string                  },
          { name: :firstname           , type: :string                  },
          { name: :lastname            , type: :string                  },
          { name: :company             , type: :string                  },
          { name: :department          , type: :string                  },
          { name: :street              , type: :string                  },
          { name: :zipcode             , type: :string                  },
          { name: :city                , type: :string                  },
          { name: :annotation          , type: :string                  },
          { name: :inactive            , type: :integer                 },
          { name: :country             , type: :string                  },
          { name: :phone               , type: :string                  },
          { name: :fax                 , type: :string                  },
          { name: :email               , type: :string                  },
          { name: :account_number      , type: :string                  },
          { name: :bank_account_number , type: :string                  },
          { name: :iban                , type: :string                  },
          { name: :bic                 , type: :string                  },
          { name: :bank_name           , type: :string                  },
          { name: :tax_id              , type: :string                  },
          { name: :vat_id              , type: :string                  },
          { name: :reserved            , type: :string                  },
          { name: :phone_2             , type: :string                  },
          { name: :skype_voip          , type: :string                  },
          { name: :url                 , type: :string                  },
          { name: :account_owner       , type: :string                  },
          { name: :review_at           , type: :date                    },
          { name: :address_group_id    , type: :integer                 },
          { name: :agent_id            , type: :integer                 },
          { name: :company_id          , type: :integer , default: 1    }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1} ) }

  output = ["CMXADR", 1, nil, "", "", "", "", "", "", "", "", "", "", nil, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", nil, nil, nil, 1]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::Cmxasp do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_anspr
  it_behaves_like "Collmex Api Command"
  spec =
      [
          { name: :identifier       , type: :string  , fix: "CMXASP" },
          { name: :id               , type: :integer                 },
          { name: :type             , type: :integer                 },
          { name: :salutation       , type: :string                  },
          { name: :title            , type: :string                  },
          { name: :firstname        , type: :string                  },
          { name: :lastname         , type: :string                  },
          { name: :company          , type: :string                  },
          { name: :department       , type: :string                  },
          { name: :street           , type: :string                  },
          { name: :zipcode          , type: :string                  },
          { name: :city             , type: :string                  },
          { name: :country          , type: :string                  },
          { name: :phone            , type: :string                  },
          { name: :phone_2          , type: :string                  },
          { name: :fax              , type: :string                  },
          { name: :skype_voip       , type: :string                  },
          { name: :email            , type: :string                  },
          { name: :annotation       , type: :string                  },
          { name: :url              , type: :string                  },
          { name: :no_mailings      , type: :integer                 },
          { name: :address_group_id , type: :integer                 }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1} ) }

  output = ["CMXASP", 1, nil, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", nil, nil]

  specify { subject.to_a.should eql output }
end

#describe Collmex::Api::Cmxbom do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Stuecklisten
  # tbd
#end

describe Collmex::Api::Cmxepf do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_abw
  it_behaves_like "Collmex Api Command"
  spec =
      [
          { name: :identifier       , type: :string  , fix: "CMXEPF" },
          { name: :customer_id      , type: :integer                 },
          { name: :company_id       , type: :integer , default: 1    },
          { name: :document_type    , type: :integer                 },
          { name: :output_media     , type: :integer                 },
          { name: :salutation       , type: :string                  },
          { name: :title            , type: :string                  },
          { name: :firstname        , type: :string                  },
          { name: :lastname         , type: :string                  },
          { name: :company          , type: :string                  },
          { name: :department       , type: :string                  },
          { name: :street           , type: :string                  },
          { name: :zipcode          , type: :string                  },
          { name: :city             , type: :string                  },
          { name: :country          , type: :string                  },
          { name: :phone            , type: :string                  },
          { name: :phone_2          , type: :string                  },
          { name: :fax              , type: :string                  },
          { name: :skype_voip       , type: :string                  },
          { name: :email            , type: :string                  },
          { name: :annotation       , type: :string                  },
          { name: :url              , type: :string                  },
          { name: :no_mailings      , type: :integer                 },
          { name: :address_group_id , type: :integer                 }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1} ) }

  output = ["CMXEPF", nil, 1, nil, nil, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", nil, nil]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::Cmxinv do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_rechnungen
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier                         , type: :string  , fix: "CMXINV" },
          { name: :id                                 , type: :integer                 },
          { name: :position_id                        , type: :integer                 },
          { name: :type                               , type: :integer                 },
          { name: :company_id                         , type: :integer , default: 1    },
          { name: :customer_order_id                  , type: :integer                 },
          { name: :customer_id                        , type: :integer                 },
          { name: :customer_salutation                , type: :string                  },
          { name: :customer_title                     , type: :string                  },
          { name: :customer_firstname                 , type: :string                  },
          { name: :customer_lastname                  , type: :string                  },
          { name: :customer_company                   , type: :string                  },
          { name: :customer_department                , type: :string                  },
          { name: :customer_street                    , type: :string                  },
          { name: :customer_zipcode                   , type: :string                  },
          { name: :customer_city                      , type: :string                  },
          { name: :customer_country                   , type: :string                  },
          { name: :customer_phone                     , type: :string                  },
          { name: :customer_phone_2                   , type: :string                  },
          { name: :customer_fax                       , type: :string                  },
          { name: :customer_email                     , type: :string                  },
          { name: :customer_account_number            , type: :string                  },
          { name: :customer_bank_account_number       , type: :string                  },
          { name: :customer_alternative_account_owner , type: :string                  },
          { name: :customer_iban                      , type: :string                  },
          { name: :customer_bic                       , type: :string                  },
          { name: :customer_bank_name                 , type: :string                  },
          { name: :customer_vat_id                    , type: :string                  },
          { name: :reserved                           , type: :integer                 },
          { name: :date                               , type: :date                    },
          { name: :price_date                         , type: :date                    },
          { name: :terms_of_payment                   , type: :integer                 },
          { name: :currency                           , type: :string                  },
          { name: :price_group_id                     , type: :integer                 },
          { name: :discount_group_id                  , type: :integer                 },
          { name: :discount_final                     , type: :integer                 },
          { name: :discount_reason                    , type: :string                  },
          { name: :text                               , type: :string                  },
          { name: :text_conclusion                    , type: :string                  },
          { name: :internal_memo                      , type: :string                  },
          { name: :deleted                            , type: :integer                 },
          { name: :language                           , type: :integer                 },
          { name: :operator_id                        , type: :integer                 },
          { name: :agent_id                           , type: :integer                 },
          { name: :system_name                        , type: :string                  },
          { name: :status                             , type: :integer                 },
          { name: :discount_final_2                   , type: :currency                },
          { name: :discount_reason_2                  , type: :string                  },
          { name: :delivery_type                      , type: :integer                 },
          { name: :delivery_costs                     , type: :currency                },
          { name: :cod_fee                            , type: :currency                },
          { name: :supply_and_service_date            , type: :date                    },
          { name: :delivery_terms                     , type: :string                  },
          { name: :delivery_terms_additions           , type: :string                  },
          { name: :delivery_address_salutation        , type: :string                  },
          { name: :delivery_address_title             , type: :string                  },
          { name: :delivery_address_firstname         , type: :string                  },
          { name: :delivery_address_lastname          , type: :string                  },
          { name: :delivery_address_company           , type: :string                  },
          { name: :delivery_address_department        , type: :string                  },
          { name: :delivery_address_street            , type: :string                  },
          { name: :delivery_address_zipcode           , type: :string                  },
          { name: :delivery_address_city              , type: :string                  },
          { name: :delivery_address_country           , type: :string                  },
          { name: :delivery_address_phone             , type: :string                  },
          { name: :delivery_address_phone_2           , type: :string                  },
          { name: :delivery_address_fax               , type: :string                  },
          { name: :delivery_address_email             , type: :string                  },
          { name: :item_category                      , type: :integer                 },
          { name: :product_id                         , type: :string                  },
          { name: :product_description                , type: :string                  },
          { name: :quantity_unit                      , type: :string                  },
          { name: :order_quantity                     , type: :float                   },
          { name: :product_price                      , type: :currency                },
          { name: :amount_price                       , type: :float                   },
          { name: :position_discount                  , type: :currency                },
          { name: :position_value                     , type: :currency                },
          { name: :product_type                       , type: :integer                 },
          { name: :tax_classification                 , type: :integer                 },
          { name: :tax_abroad                         , type: :integer                 },
          { name: :customer_order_position            , type: :integer                 },
          { name: :revenue_element                    , type: :integer                 }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1, customer_id: 9999} ) }

  output = ["CMXINV", 1, nil, nil, 1, nil, 9999, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", nil, nil, nil, nil, "", nil, nil, nil, "", "", "", "", nil, nil, nil, nil, "", nil, nil, "", nil, nil, nil, nil, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", nil, "", "", "", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::Cmxknd do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_kunde
  it_behaves_like "Collmex Api Command"
  spec =
      [
          { name: :identifier                     , type: :string  , fix: "CMXKND" },
          { name: :id                             , type: :integer                 },
          { name: :company_id                     , type: :integer , default: 1    },
          { name: :salutation                     , type: :string                  },
          { name: :title                          , type: :string                  },
          { name: :firstname                      , type: :string                  },
          { name: :lastname                       , type: :string                  },
          { name: :company                        , type: :string                  },
          { name: :department                     , type: :string                  },
          { name: :street                         , type: :string                  },
          { name: :zipcode                        , type: :string                  },
          { name: :city                           , type: :string                  },
          { name: :annotation                     , type: :string                  },
          { name: :inactive                       , type: :integer                 },
          { name: :country                        , type: :string                  },
          { name: :phone                          , type: :string                  },
          { name: :fax                            , type: :string                  },
          { name: :email                          , type: :string                  },
          { name: :account_number                 , type: :string                  },
          { name: :bank_account_number            , type: :string                  },
          { name: :iban                           , type: :string                  },
          { name: :bic                            , type: :string                  },
          { name: :bank_name                      , type: :string                  },
          { name: :tax_id                         , type: :string                  },
          { name: :vat_id                         , type: :string                  },
          { name: :payment_condition              , type: :integer                 },
          { name: :discount_group_id              , type: :integer                 },
          { name: :delivery_terms                 , type: :string                  },
          { name: :delivery_terms_additions       , type: :string                  },
          { name: :output_media                   , type: :integer                 },
          { name: :account_owner                  , type: :string                  },
          { name: :address_group_id               , type: :integer                 },
          { name: :ebay_member                    , type: :string                  },
          { name: :price_group_id                 , type: :integer                 },
          { name: :currency                       , type: :string                  },
          { name: :agent_id                       , type: :integer                 },
          { name: :cost_unit                      , type: :string                  },
          { name: :due_to_review                  , type: :date                    },
          { name: :delivery_block                 , type: :integer                 },
          { name: :construction_services_provider , type: :integer                 },
          { name: :delivery_id_at_customer        , type: :string                  },
          { name: :output_language                , type: :integer                 },
          { name: :email_cc                       , type: :string                  },
          { name: :phone_2                        , type: :string                  }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1} ) }

  output = ["CMXKND", 1, 1, "", "", "", "", "", "", "", "", "", "", nil, "", "", "", "", "", "", "", "", "", "", "", nil, nil, "", "", nil, "", nil, "", nil, "", nil, "", nil, nil, nil, "", nil, "", ""]

  specify { subject.to_a.should eql output }
end

#describe Collmex::Api::Cmxknt do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_kontakte
  # tbd
#end

describe Collmex::Api::Cmxlif do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_lieferant
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier               , type: :string  , fix: "CMXLIF" },
          { name: :id                       , type: :integer                 },
          { name: :company_id               , type: :integer , default: 1    },
          { name: :salutation               , type: :string                  },
          { name: :title                    , type: :string                  },
          { name: :firstname                , type: :string                  },
          { name: :lastname                 , type: :string                  },
          { name: :company                  , type: :string                  },
          { name: :department               , type: :string                  },
          { name: :street                   , type: :string                  },
          { name: :zipcode                  , type: :string                  },
          { name: :city                     , type: :string                  },
          { name: :annotation               , type: :string                  },
          { name: :inactive                 , type: :integer                 },
          { name: :country                  , type: :string                  },
          { name: :phone                    , type: :string                  },
          { name: :fax                      , type: :string                  },
          { name: :email                    , type: :string                  },
          { name: :account_number           , type: :string                  },
          { name: :bank_account_number      , type: :string                  },
          { name: :iban                     , type: :string                  },
          { name: :bic                      , type: :string                  },
          { name: :bank_name                , type: :string                  },
          { name: :tax_id                   , type: :string                  },
          { name: :vat_id                   , type: :string                  },
          { name: :payment_condition        , type: :integer                 },
          { name: :delivery_terms           , type: :string                  },
          { name: :delivery_terms_additions , type: :string                  },
          { name: :output_media             , type: :integer                 },
          { name: :account_owner            , type: :string                  },
          { name: :address_group_id         , type: :integer                 },
          { name: :customer_id_at_supplier  , type: :string                  },
          { name: :currency                 , type: :string                  },
          { name: :phone_2                  , type: :string                  },
          { name: :output_language          , type: :integer                 }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1} ) }

  output = ["CMXLIF", 1, 1, "", "", "", "", "", "", "", "", "", "", nil, "", "", "", "", "", "", "", "", "", "", "", nil, "", "", nil, "", nil, "", "", "", nil]

  specify { subject.to_a.should eql output }
end

#describe Collmex::Api::Cmxlrn do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_lieferantenrechnung
  # tbd
#end

#describe Collmex::Api::Cmxord_2 do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_kundenauftraege
  # tbd
#end

#describe Collmex::Api::Cmxpod do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_produktionsauftraege
  # tbd
#end

#describe Collmex::Api::Cmxprd do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_produkt
  # tbd
#end

describe Collmex::Api::Cmxpri do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_preise
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier     , type: :string  , fix: "CMXPRI" },
          { name: :product_id     , type: :string                  },
          { name: :company_id     , type: :integer , default: 1    },
          { name: :price_group_id , type: :integer                 },
          { name: :valid_from     , type: :date                    },
          { name: :valid_to       , type: :date                    },
          { name: :product_price  , type: :currency                }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {product_id: 9999} ) }

  output = ["CMXPRI", "9999", 1, nil, nil, nil, nil]

  specify { subject.to_a.should eql output }
end

#describe Collmex::Api::Cmxprj do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Projekte
  # tbd
#end

#describe Collmex::Api::Cmxprl do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_lohn
  # tbd
#end

describe Collmex::Api::Cmxqtn do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_angebote
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier                         , type: :string  , fix: "CMXQTN" },
          { name: :id                                 , type: :integer                 },
          { name: :position_id                        , type: :integer                 },
          { name: :type                               , type: :integer                 },
          { name: :company_id                         , type: :integer , default: 1    },
          { name: :customer_id                        , type: :integer                 },
          { name: :customer_salutation                , type: :string                  },
          { name: :customer_title                     , type: :string                  },
          { name: :customer_firstname                 , type: :string                  },
          { name: :customer_lastname                  , type: :string                  },
          { name: :customer_company                   , type: :string                  },
          { name: :customer_department                , type: :string                  },
          { name: :customer_street                    , type: :string                  },
          { name: :customer_zipcode                   , type: :string                  },
          { name: :customer_city                      , type: :string                  },
          { name: :customer_country                   , type: :string                  },
          { name: :customer_phone                     , type: :string                  },
          { name: :customer_phone_2                   , type: :string                  },
          { name: :customer_fax                       , type: :string                  },
          { name: :customer_email                     , type: :string                  },
          { name: :customer_account_number            , type: :string                  },
          { name: :customer_bank_account_number       , type: :string                  },
          { name: :customer_alternative_account_owner , type: :string                  },
          { name: :customer_iban                      , type: :string                  },
          { name: :customer_bic                       , type: :string                  },
          { name: :customer_bank_name                 , type: :string                  },
          { name: :customer_vat_id                    , type: :string                  },
          { name: :reserved_1                         , type: :integer                 },
          { name: :date                               , type: :date                    },
          { name: :price_date                         , type: :date                    },
          { name: :terms_of_payment                   , type: :integer                 },
          { name: :currency                           , type: :string                  },
          { name: :price_group_id                     , type: :integer                 },
          { name: :discount_group_id                  , type: :integer                 },
          { name: :discount_final                     , type: :integer                 },
          { name: :discount_reason                    , type: :string                  },
          { name: :text                               , type: :string                  },
          { name: :text_conclusion                    , type: :string                  },
          { name: :internal_memo                      , type: :string                  },
          { name: :deleted                            , type: :integer                 },
          { name: :rejected_at                        , type: :date                    },
          { name: :language                           , type: :integer                 },
          { name: :operator_id                        , type: :integer                 },
          { name: :agent_id                           , type: :integer                 },
          { name: :discount_final_2                   , type: :currency                },
          { name: :discount_reason_2                  , type: :string                  },
          { name: :reserved_2                         , type: :string                  },
          { name: :reserved_3                         , type: :string                  },
          { name: :delivery_type                      , type: :integer                 },
          { name: :delivery_costs                     , type: :currency                },
          { name: :cod_fee                            , type: :currency                },
          { name: :supply_and_service_date            , type: :date                    },
          { name: :delivery_terms                     , type: :string                  },
          { name: :delivery_terms_additions           , type: :string                  },
          { name: :delivery_address_salutation        , type: :string                  },
          { name: :delivery_address_title             , type: :string                  },
          { name: :delivery_address_firstname         , type: :string                  },
          { name: :delivery_address_lastname          , type: :string                  },
          { name: :delivery_address_company           , type: :string                  },
          { name: :delivery_address_department        , type: :string                  },
          { name: :delivery_address_street            , type: :string                  },
          { name: :delivery_address_zipcode           , type: :string                  },
          { name: :delivery_address_city              , type: :string                  },
          { name: :delivery_address_country           , type: :string                  },
          { name: :delivery_address_phone             , type: :string                  },
          { name: :delivery_address_phone_2           , type: :string                  },
          { name: :delivery_address_fax               , type: :string                  },
          { name: :delivery_address_email             , type: :string                  },
          { name: :item_category                      , type: :integer                 },
          { name: :product_id                         , type: :string                  },
          { name: :product_description                , type: :string                  },
          { name: :quantity_unit                      , type: :string                  },
          { name: :order_quantity                     , type: :float                   },
          { name: :product_price                      , type: :currency                },
          { name: :amount_price                       , type: :float                   },
          { name: :position_discount                  , type: :currency                },
          { name: :position_value                     , type: :currency                },
          { name: :product_type                       , type: :integer                 },
          { name: :tax_classification                 , type: :integer                 },
          { name: :tax_abroad                         , type: :integer                 },
          { name: :revenue_element                    , type: :integer                 }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1, customer_id: 9999} ) }

  output = ["CMXQTN", 1, nil, nil, 1, 9999, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", nil, nil, nil, nil, "", nil, nil, nil, "", "", "", "", nil, nil, nil, nil, nil, nil, "", "", "", nil, nil, nil, nil, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", nil, "", "", "", nil, nil, nil, nil, nil, nil, nil, nil, nil]

  specify { subject.to_a.should eql output }
end

#describe Collmex::Api::Cmxstk do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_bestand
  # tbd
#end

describe Collmex::Api::Cmxums do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_umsaetze
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier                , type: :string   , fix: "CMXUMS" },
          { name: :customer_id               , type: :integer                  },
          { name: :company_id                , type: :integer  , default: 1    },
          { name: :invoice_date              , type: :date                     },
          { name: :invoice_id                , type: :string                   },
          { name: :net_amount_full_vat       , type: :currency                 },
          { name: :tax_value_full_vat        , type: :currency                 },
          { name: :net_amount_reduced_vat    , type: :currency                 },
          { name: :tax_value_reduced_vat     , type: :currency                 },
          { name: :intra_community_delivery  , type: :currency                 },
          { name: :export                    , type: :currency                 },
          { name: :account_id_no_vat         , type: :integer                  },
          { name: :net_amount_no_vat         , type: :currency                 },
          { name: :currency                  , type: :string                   },
          { name: :contra_account            , type: :integer                  },
          { name: :invoice_type              , type: :integer                  },
          { name: :text                      , type: :string                   },
          { name: :terms_of_payment          , type: :integer                  },
          { name: :account_id_full_vat       , type: :integer                  },
          { name: :account_id_reduced_vat    , type: :integer                  },
          { name: :reserved_1                , type: :integer                  },
          { name: :reserved_2                , type: :integer                  },
          { name: :cancellation              , type: :integer                  },
          { name: :final_invoice             , type: :string                   },
          { name: :type                      , type: :integer                  },
          { name: :system_name               , type: :string                   },
          { name: :offset_against_invoice_id , type: :string                   },
          { name: :cost_unit                 , type: :string                   }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {customer_id: 9999} ) }

  output = ["CMXUMS", 9999, 1, nil, "", nil, nil, nil, nil, nil, nil, nil, nil, "", nil, nil, "", nil, nil, nil, nil, nil, nil, "", nil, "", "", ""]

  specify { subject.to_a.should eql output }
end

#describe Collmex::Api::CreateDueDeliveries do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Faellige_Lieferungen
  # tbd
#end

describe Collmex::Api::CustomerGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Kunden
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier        , type: :string  , fix: "CUSTOMER_GET" },
          { name: :id                , type: :integer                       },
          { name: :company_id        , type: :integer , default: 1          },
          { name: :text              , type: :string                        },
          { name: :due_to_review     , type: :integer                       },
          { name: :zip_code          , type: :string                        },
          { name: :address_group_id  , type: :integer                       },
          { name: :price_group_id    , type: :integer                       },
          { name: :discount_group_id , type: :integer                       },
          { name: :agent_id          , type: :integer                       },
          { name: :only_changed      , type: :integer                       },
          { name: :system_name       , type: :string                        },
          { name: :inactive          , type: :integer                       }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1} ) }

  output = ["CUSTOMER_GET", 1, 1, "", nil, "", nil, nil, nil, nil, nil, "", nil]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::DeliveryGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Lieferungen
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier        , type: :string  , fix: "DELIVERY_GET" },
          { name: :id                , type: :string                        },
          { name: :company_id        , type: :integer , default: 1          },
          { name: :customer_id       , type: :integer                       },
          { name: :date_start        , type: :date                          },
          { name: :date_end          , type: :date                          },
          { name: :sent_only         , type: :integer                       },
          { name: :return_format     , type: :string                        },
          { name: :only_changed      , type: :integer                       },
          { name: :system_name       , type: :string                        },
          { name: :paperless         , type: :integer                       },
          { name: :customer_order_id , type: :integer                       }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1, customer_id: 9999} ) }

  output = ["DELIVERY_GET", "1", 1, 9999, nil, nil, nil, "", nil, "", nil, nil]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::InvoiceGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Rechnungen
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier       , type: :string  , fix: "INVOICE_GET" },
          { name: :id               , type: :string                       },
          { name: :company_id       , type: :integer , default: 1         },
          { name: :customer_id      , type: :integer                      },
          { name: :date_start       , type: :date                         },
          { name: :date_end         , type: :date                         },
          { name: :sent_only        , type: :integer                      },
          { name: :return_format    , type: :string                       },
          { name: :only_changed     , type: :integer                      },
          { name: :system_name      , type: :string                       },
          { name: :system_name_only , type: :integer                      },
          { name: :paperless        , type: :integer                      }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1, customer_id: 9999} ) }

  output = ["INVOICE_GET", "1", 1, 9999, nil, nil, nil, "", nil, "", nil, nil]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::InvoicePayment do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Zahlungen
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier      , type: :string   , fix: "INVOICE_PAYMENT" },
          { name: :id              , type: :string                            },
          { name: :date            , type: :date                              },
          { name: :amount_paid     , type: :currency                          },
          { name: :amount_reduced  , type: :currency                          },
          { name: :business_year   , type: :integer                           },
          { name: :accdoc_id       , type: :integer                           },
          { name: :accdoc_position , type: :integer                           }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1} ) }

  output = ["INVOICE_PAYMENT", "1", nil, nil, nil, nil, nil, nil]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::InvoicePaymentGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Zahlungen
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier   , type: :string  , fix: "INVOICE_PAYMENT_GET" },
          { name: :company_id   , type: :integer , default: 1                 },
          { name: :id           , type: :string                               },
          { name: :changed_only , type: :integer                              },
          { name: :system_name  , type: :string                               }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1} ) }

  output = ["INVOICE_PAYMENT_GET", 1, "1", nil, ""]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::Line do
  it_behaves_like "Collmex Api Command" 
end

describe Collmex::Api::Login do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Authentifizierung
  subject { Collmex::Api::Login.new({username: 12, password: 34}) }
  it_behaves_like "Collmex Api Command" 
  spec =  
      [
          { name: :identifier , type: :string  , fix: "LOGIN" },
          { name: :username   , type: :integer                },
          { name: :password   , type: :integer                }
      ]

  specify { described_class.specification.should eql spec } 

  output = ["LOGIN", 12, 34]
  specify { subject.to_a.should eql output }
end

describe Collmex::Api::Message do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Rueckmeldungen
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier , type: :string  , fix: "MESSAGE" },
          { name: :type       , type: :string                   },
          { name: :id         , type: :integer                  },
          { name: :text       , type: :string                   },
          { name: :line       , type: :integer                  }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new(  ) }

  output = ["MESSAGE", "", nil, "", nil]

  specify { subject.to_a.should eql output }

  context "success" do
    subject { described_class.new(type: "S") }
    specify do
      subject.success?.should eql true
      subject.result.should eql :success
    end
  end

  context "warning" do
    subject { described_class.new(type: "W") }
    specify do
      subject.success?.should eql false
      subject.result.should eql :warning
    end
  end

  context "error" do
    subject { described_class.new(type: "E") }
    specify do
      subject.success?.should eql false
      subject.result.should eql :error
    end
  end

  context "undefined" do
    subject { described_class.new() }
    specify do
      subject.success?.should eql false
      subject.result.should eql :undefined
    end
  end
end

describe Collmex::Api::PaymentConfirmation do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Payment
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier            , type: :string   , fix: "PAYMENT_CONFIRMATION" },
          { name: :customer_order_id     , type: :integer                                },
          { name: :date                  , type: :date                                   },
          { name: :amount                , type: :currency                               },
          { name: :fee                   , type: :currency                               },
          { name: :currency              , type: :string                                 },
          { name: :paypal_email          , type: :string                                 },
          { name: :paypal_transaction_id , type: :string                                 }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {customer_order_id: 1} ) }

  output = ["PAYMENT_CONFIRMATION", 1, nil, nil, nil, "", "", ""]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::Prdgrp do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_produktgruppen
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier               , type: :string  , fix: "PRDGRP" },
          { name: :id                       , type: :integer                 },
          { name: :description              , type: :string                  },
          { name: :generic_product_group_id , type: :integer                 }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1} ) }

  output = ["PRDGRP", 1, "", nil]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::ProductGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Produkte
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier      , type: :string  , fix: "PRODUCT_GET" },
          { name: :company_id      , type: :integer , default: 1         },
          { name: :id              , type: :string                       },
          { name: :group           , type: :integer                      },
          { name: :price_group_id  , type: :string                       },
          { name: :changed_only    , type: :integer                      },
          { name: :system_name     , type: :string                       },
          { name: :website_id      , type: :integer                      }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1} ) }

  output = ["PRODUCT_GET", 1, "1", nil, "", nil, "", nil]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::ProductGroupsGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Produktgruppen
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier , type: :string , fix: "PRODUCT_GROUPS_GET" }
      ]

  specify { described_class.specification.should eql spec }

  output = ["PRODUCT_GROUPS_GET"]

  specify { subject.to_a.should eql output }
end

#describe Collmex::Api::ProductionOrderGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Produktionsauftraege
  # tbd
#end

describe Collmex::Api::ProjectGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Projekte
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier  , type: :string  , fix: "PROJECT_GET " },
          { name: :id          , type: :integer                       },
          { name: :company_id  , type: :integer , default: 1          },
          { name: :customer_id , type: :integer                       }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1} ) }

  output = ["PROJECT_GET ", 1, 1, nil]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::PurchaseOrderGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Lieferantenauftraege
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier    , type: :string  , fix: "PURCHASE_ORDER_GET" },
          { name: :id            , type: :string                              },
          { name: :company_id    , type: :integer , default: 1                },
          { name: :supplier_id   , type: :integer                             },
          { name: :product_id    , type: :string                              },
          { name: :sent_only     , type: :integer                             },
          { name: :return_format , type: :string                              },
          { name: :only_changed  , type: :integer                             },
          { name: :system_name   , type: :string                              },
          { name: :paperless     , type: :integer                             }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1, supplier_id: 9999} ) }

  output = ["PURCHASE_ORDER_GET", "1", 1, 9999, "", nil, "", nil, "", nil]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::QuotationGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Angebote
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier    , type: :string  , fix: "QUOTATION_GET" },
          { name: :id            , type: :string                         },
          { name: :company_id    , type: :integer , default: 1           },
          { name: :customer_id   , type: :integer                        },
          { name: :date_start    , type: :date                           },
          { name: :date_end      , type: :date                           },
          { name: :paperless     , type: :integer                        },
          { name: :return_format , type: :string                         },
          { name: :only_changed  , type: :integer                        },
          { name: :system_name   , type: :string                         }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1, customer_id: 9999} ) }

  output = ["QUOTATION_GET", "1", 1, 9999, nil, nil, nil, "", nil, ""]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::SalesOrderGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Kundenauftraege
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier       , type: :string  , fix: "SALES_ORDER_GET" },
          { name: :id               , type: :string                           },
          { name: :company_id       , type: :integer , default: 1             },
          { name: :customer_id      , type: :integer                          },
          { name: :date_start       , type: :date                             },
          { name: :date_end         , type: :date                             },
          { name: :id_at_customer   , type: :string                           },
          { name: :return_format    , type: :string                           },
          { name: :only_changed     , type: :integer                          },
          { name: :system_name      , type: :string                           },
          { name: :system_name_only , type: :integer                          },
          { name: :paperless        , type: :integer                          }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1, customer_id: 9999} ) }

  output = ["SALES_ORDER_GET", "1", 1, 9999, nil, nil, "", "", nil, "", nil, nil]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::SearchEngineProductsGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Suchmaschinen
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier    , type: :string  , fix: "SEARCH_ENGINE_PRODUCTS_GET" },
          { name: :website_id    , type: :integer                                     },
          { name: :return_format , type: :integer                                     }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1, customer_id: 9999} ) }

  output = ["SEARCH_ENGINE_PRODUCTS_GET", nil, nil]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::StockAvailable do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Verfuegbarkeit
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier         , type: :string  , fix: "STOCK_AVAILABLE" },
          { name: :product_id         , type: :string                           },
          { name: :company_id         , type: :integer , default: 1             },
          { name: :amount             , type: :integer                          },
          { name: :quantity_unit      , type: :string                           },
          { name: :replenishment_time , type: :integer                          }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {product_id: 1} ) }

  output = ["STOCK_AVAILABLE", "1", 1, nil, "", nil]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::StockAvailableGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Verfuegbarkeit
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier   , type: :string  , fix: "STOCK_AVAILABLE_GET" },
          { name: :company_id   , type: :integer , default: 1                 },
          { name: :product_id   , type: :string                               },
          { name: :changed_only , type: :integer                              },
          { name: :system_name  , type: :string                               }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {product_id: 1} ) }

  output = ["STOCK_AVAILABLE_GET", 1, "1", nil, ""]

  specify { subject.to_a.should eql output }
end

#describe Collmex::Api::StockChange do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Bestandsaenderungen
  # tbd
#end

#describe Collmex::Api::StockChangeGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Bestandsaenderungen
  # tbd
#end

describe Collmex::Api::TrackingNumber do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_sendungsnummer
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier  , type: :string  , fix: "TRACKING_NUMBER" },
          { name: :delivery_id , type: :integer                          },
          { name: :id          , type: :string                           }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {id: 1} ) }

  output = ["TRACKING_NUMBER", nil, "1"]

  specify { subject.to_a.should eql output }
end

describe Collmex::Api::VendorGet do # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Lieferanten
  it_behaves_like "Collmex Api Command"

  spec =
      [
          { name: :identifier    , type: :string  , fix: "VENDOR_GET" },
          { name: :delivery_id   , type: :integer                     },
          { name: :company_id    , type: :integer , default: 1        },
          { name: :text          , type: :string                      },
          { name: :due_to_review , type: :integer                     },
          { name: :zip_code      , type: :string                      },
          { name: :only_changed  , type: :integer                     },
          { name: :system_name   , type: :string                      }
      ]

  specify { described_class.specification.should eql spec }

  subject { described_class.new( {delivery_id: 1} ) }

  output = ["VENDOR_GET", 1, 1, "", nil, "", nil, ""]

  specify { subject.to_a.should eql output }

end

