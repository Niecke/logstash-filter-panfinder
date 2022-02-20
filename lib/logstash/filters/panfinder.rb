# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::Panfinder < LogStash::Filters::Base

  # Setting the config_name here is required. This is how you
  # configure this filter from your Logstash config.
  #
  # filter {
  #   panfinder {
  #     source => "message"
  #     luhn => true
  #     sanitize => false
  #     extended => false
  #   }
  # }
  #
  config_name "panfinder"

  config :source, :validate => :string, :default => 'message'
  config :luhn, :validate => :boolean, :default => true
  config :sanitize, :validate => :boolean, :default => false
  config :extended, :validate => :boolean, :default => false

  public
  def register
  end # def register

  public
  def filter(event)

    # this array will contain all numbers that satisfy the regex
    pans_maybe = []
    # this array will contain all pans which will be added to event
    pans_valid = []

    msg = event.get(@source)

    unless msg
      return
    end

    # match all elements from 14-19 numbers 
    # https://baymard.com/checkout-usability/credit-card-patterns
    # https://regex101.com/r/nDQwVZ/1
    # following patterns match 
    # 4-4-4-4
    # 4-4-4-4-3
    # 4-4-5
    # 4-5-6
    # 4-6-4
    # 4-6-5
    # and everythin with 13-19 digits without any special characters
    pans_maybe = msg.scan(/(\D|^)((\d{13,19})|(\d{4}\D{0,1}((\d{4}\D{0,1}\d{4}\D{0,1}\d{4}(\D{0,1}\d{3}|))|(\d{4}\D{0,1}\d{5})|(\d{5}\D{0,1}\d{6})|\d{6}\D{0,1}(\d{5}|\d{4}))))(\D|$)/)

    unless pans_maybe.empty?
      pans_maybe.each do |pan_number_match|
        pan_number = pan_number_match[1]
        # if luhn is enabled check the pan_number otherwise always add the pan_number
        if (not @luhn) || luhn_valid?(pan_number)
          pans_valid.append(pan_number)
          if @sanitize 
            msg = msg.gsub(pan_number, "###! sanitized PAN !###")
          end
        end
      end
      # if any pans where valid add them to the event
      unless pans_valid.empty?
        event.set("pans", pans_valid)
        if @sanitize
          event.set(@source, msg)
        end

        # if extended check is enabled go through the pans again
        if @extended
          visa_pans = []
          mc_pans = []
          amex_pans = []
          pans_valid.each do |pan_number_match|
            # visa
            if pan_number_match =~ /^(4\d{3}.?(\d{4}.?){3})$/
              visa_pans.append(pan_number_match)
            end

            # mastercard
            if pan_number_match =~ /^(5[1-5]\d{2}.?(\d{4}.?){3})|(2[2-7]\d{2}.?(\d{4}.?){3})$/
              mc_pans.append(pan_number_match)
            end

            # american express
            if pan_number_match =~ /^((34|37)\d{2}.?\d{6}.?\d{5})$/
              amex_pans.append(pan_number_match)
            end
          end
          
          unless visa_pans.empty?
            event.set("pans_visa", visa_pans)
          end

          unless mc_pans.empty?
            event.set("pans_mc", mc_pans)
          end

          unless amex_pans.empty?
            event.set("pans_amex", amex_pans)
          end
        end
      end
    end

    @logger.debug? && @logger.debug("PANs found: #{event.get("pans")}")

    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end # def filter

  private
  # https://stackoverflow.com/questions/9188360/implementing-the-luhn-algorithm-in-ruby
  def luhn_valid?(cc_number)
    number = cc_number.
      gsub(/\D/, ''). # remove non-digits
      reverse  # read from right to left
  
    sum, i = 0, 0
  
    number.each_char do |ch|
      n = ch.to_i
  
      # Step 1
      n *= 2 if i.odd?
  
      # Step 2
      n = 1 + (n - 10) if n >= 10
  
      sum += n
      i   += 1
    end
  
    # Step 3
    (sum % 10).zero?
  end

end # class LogStash::Filters::Panfinder
