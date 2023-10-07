# encoding: utf-8
require 'spec_helper'
require "logstash/filters/panfinder"

describe LogStash::Filters::Panfinder do
  describe "Panfinder tests" do
    let(:config) do <<-CONFIG
      filter {
        panfinder {
        }
      }
    CONFIG
    end

    sample("message" => "some text") do
      expect(subject.get("pans")).to be_nil
    end

    pans = {
      # Visa
      "text 4111111111111111 some more text"    => {'simple' => ["4111111111111111"]},
      "text 4111141011111111116 some more text" => {'simple' => ["4111141011111111116"]},

      # Mastercard
      "text 5500000000000004 some more text" => {'simple' => ["5500000000000004"]},
      "text 2720990000000015 some more text" => {'simple' => ["2720990000000015"]},
      
      # Maestro
      "text 67012345678901236 some more text" => {'simple' => ["67012345678901236"]},

      # AMEX
      "text 340000000000009 some more text" => {'simple' => ["340000000000009"]},
      "text 370000000000002 some more text" => {'simple' => ["370000000000002"]},

      # JCB
      "text 3528000000000007 some more text" => {'simple' => ["3528000000000007"]},

      # Diners/Discover
      "text 30000000000004 some more text" => {'simple' => ["30000000000004"]},
      "text 6011111111111117 some more text" => {'simple' => ["6011111111111117"]},
    }

    pans.each do |input, output|
      sample("message" => input) do
        expect(subject.get("pans")).to eq(output)
      end
    end

    # test data which are not luhn compatible
    pans_no_lun = [
      "text 4111111112111111 some more text",
      "text 4111141011111211116 some more text",
      "text 5500000010000004 some more text",
      "text 2720990001000015 some more text",
      "text 67012345679901236 some more text",
      "text 340000010000009 some more text",
      "text 370000010000002 some more text",
      "text 3528000100000007 some more text",
      "text 30000001000004 some more text",
      "text 6011111211111117 some more text",
    ]
    pans_no_lun.each do |input|
      sample("message" => input) do
        expect(subject.get("pans")).to be_nil
      end
    end

    # formated pans
    pans_formated = {
      # Visa
      "text 4111 1111 1111 1111 some more text"    => {'simple' => ["4111 1111 1111 1111"]},
      "text 4111.1111.1111.1111 some more text"    => {'simple' => ["4111.1111.1111.1111"]},

      # Mastercard
      "text 5500 0000 0000 0004 some more text" => {'simple' => ["5500 0000 0000 0004"]},
      "text 2720#9900#0000#0015 some more text" => {'simple' => ["2720#9900#0000#0015"]},
      
      # AMEX
      "text 3400 000000 00009 some more text" => {'simple' => ["3400 000000 00009"]},
      "text 3700-000000-00002 some more text" => {'simple' => ["3700-000000-00002"]},

      # JCB
      "text 3528 0000 0000 0007 some more text" => {'simple' => ["3528 0000 0000 0007"]},

      # Diners/Discover
      "text 3000 000000 0004 some more text" => {'simple' => ["3000 000000 0004"]},
      "text 6011 1111 1111 1117 some more text" => {'simple' => ["6011 1111 1111 1117"]},
    }
    pans_formated.each do |input, output|
      sample("message" => input) do
        expect(subject.get("pans")).to eq(output)
      end
    end

    # multiple pan
    pans_formated = {
      "text 4111 1111 1111 1111 some more text 2720#9900#0000#0015 and not luhn 67012345679901236"    => {'simple' => ["4111 1111 1111 1111", "2720#9900#0000#0015"]},
    }
    pans_formated.each do |input, output|
      sample("message" => input) do
        expect(subject.get("pans")).to eq(output)
      end
    end

  end

  describe "Panfinder tests without luhn check" do
    let(:config) do <<-CONFIG
      filter {
        panfinder {
          luhn => false
        }
      }
    CONFIG
    end

    # multiple pan
    pans_formated = {
      "text 4111 1111 1111 1111 some more text 2720#9900#0000#0015 and not luhn 67012345679901236"    => {"simple" => ["4111 1111 1111 1111", "2720#9900#0000#0015", "67012345679901236"]},
    }
    pans_formated.each do |input, output|
      sample("message" => input) do
        expect(subject.get("pans")).to eq(output)
      end
    end
  end

  describe "Panfinder with sanitize" do
    let(:config) do <<-CONFIG
      filter {
        panfinder {
          luhn => true
          sanitize => true
        }
      }
    CONFIG
    end
  
    # multiple pan
    pans_formated = {
      "text 4111 1111 1111 1111 some more text 2720#9900#0000#0015 and not luhn 67012345679901236"    => "text ###! sanitized PAN !### some more text ###! sanitized PAN !### and not luhn 67012345679901236",
    }
    pans_formated.each do |input, output|
      sample("message" => input) do
        expect(subject.get("message")).to eq(output)
      end
    end
  end

  describe "Panfinder with sanitize" do
    let(:config) do <<-CONFIG
      filter {
        panfinder {
          luhn => false
          sanitize => true
        }
      }
    CONFIG
    end
  
    # multiple pan
    pans_formated = {
      "text 4111 1111 1111 1111 some more text 2720#9900#0000#0015 and not luhn 67012345679901236"    => "text ###! sanitized PAN !### some more text ###! sanitized PAN !### and not luhn ###! sanitized PAN !###",
    }
    pans_formated.each do |input, output|
      sample("message" => input) do
        expect(subject.get("message")).to eq(output)
      end
    end
  end

  describe "Panfinder with extended" do
    let(:config) do <<-CONFIG
      filter {
        panfinder {
          luhn => false
          extended => true
        }
      }
    CONFIG
    end
  
    # extended pan check
    pans_formated = {
        # Visa
        "text 4111 1111 1111 1111 some more text"    => { "pans_visa": ["4111 1111 1111 1111"]},
        "text 4111.1111.1111.1111 some more text"    => { "pans_visa": ["4111.1111.1111.1111"]},
  
        # Mastercard
        "text 5100 0000 0000 0004 some more text" => { "pans_mc": ["5100 0000 0000 0004"]},
        "text 2720#9900#0000#0015 some more text" => { "pans_mc": ["2720#9900#0000#0015"]},
        
        # VISA + MC
        "text 5100 0000 0000 0004 some more text 4111.1111.1111.1111" => { "pans_mc": ["5100 0000 0000 0004"], "pans_visa": ["4111.1111.1111.1111"]},

        # AMEX
        "text 3400 000000 00009 some more text" => { "pans_amex": ["3400 000000 00009"]},
        "text 3700-000000-00002 some more text" => { "pans_amex": ["3700-000000-00002"]},
  
        # JCB
        #"text 3528 0000 0000 0007 some more text" => "3528 0000 0000 0007",
  
        # Diners/Discover
        "text 3000 000000 0004 some more text" => { "pans_diners": ["3000 000000 0004"]},
        "text 6011 1111 1111 1117 some more text" => { "pans_discover": ["6011 1111 1111 1117"]},
    }
    pans_formated.each do |input, output|
      sample("message" => input) do
        expect(subject.get("pans")['visa']).to eq(output[:pans_visa])
        expect(subject.get("pans")['mc']).to eq(output[:pans_mc])
        expect(subject.get("pans")['amex']).to eq(output[:pans_amex])
        expect(subject.get("pans")['discover']).to eq(output[:pans_discover])
      end
    end


  end

end



