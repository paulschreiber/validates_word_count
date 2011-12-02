# encoding: UTF-8

module ActiveRecord
  module Validations
    module ClassMethods
      TAG_RE = /<.[^<>]*?>/
      PUNCTUATION_RE = /[–—.(),;:!?%#$‘’“”\'"_+=\/-]*/
      WHITESPACE_RE = /(&nbsp;|&#160;|[ ])+/i
      
      def word_count_for_string(s)
        cleaned_text = s.gsub(TAG_RE, ' ').gsub(PUNCTUATION_RE,'').gsub(WHITESPACE_RE, ' ')
        cleaned_text.scan(/[\w-]+/).size
      end
      
      def validates_word_count(*args)
        configuration = {:on => :save, :with => nil}
        configuration.update(args.pop) if args.last.is_a?(Hash)

        maximum = minimum = item_name = nil

        if configuration[:in] and configuration[:in].is_a?(Range)
          minimum = configuration[:in].min
          maximum = configuration[:in].max
        else
          if configuration[:minimum] and configuration[:minimum].is_a?(Fixnum)
            minimum = configuration[:minimum].to_i
          end

          if configuration[:maximum] and configuration[:maximum].is_a?(Fixnum)
            maximum = configuration[:maximum].to_i
          end
        end
        
        if maximum.nil? and minimum.nil?
          raise "Must supply a maximum or minimum word count"
        end
        
        if !maximum.nil? and maximum == 0
          raise "Maximum word count must be greater than 0"
        end
        
        if !maximum.nil? and !minimum.nil?
          if minimum > maximum
            raise "Minimum word count (#{minimum}) cannot be greater than maximum (#{maximum})"
          end
        end
                
        validates_each(args, configuration) do |record, attr_name, value|
          next if value.nil?
          
          word_count = word_count_for_string(value)

          # if we can know what attribute is too long/short, use a _with_name
          # error message to help the user
          if configuration[:item_name].is_a?(Symbol) and record.respond_to?(configuration[:item_name])
            item_name = record.send(configuration[:item_name])
          end
          attribute_name = item_name.present? ? "#{attr_name}_with_name" : attr_name
          
          # to determine the error message:
          # - look for a translation of something attribute-sepecific (likely in the app's en.yml)
          # - look for a translation of something model-sepecific (likely in the app's en.yml)
          # - look for something passed in as a parameter (:too_many_words => "")
          # - look for a translation of the default error message (likely in the plugin's en.yml)
          if !maximum.nil? and (word_count > maximum)
            message = I18n.t("activerecord.errors.models.#{name.underscore}.attributes.#{attribute_name}.too_many_words", :words => maximum, :name => item_name,
                        :default => [:"activerecord.errors.models.#{name.underscore}.too_many_words",
                                    configuration[:too_many_words],
                                    :'activerecord.errors.messages.too_many_words'])
            record.errors.add(attr_name, message)

          elsif !minimum.nil? and (word_count < minimum)
            message = I18n.t("activerecord.errors.models.#{name.underscore}.attributes.#{attribute_name}.too_few_words", :words => minimum, :name => item_name,
                        :default => [:"activerecord.errors.models.#{name.underscore}.too_few_words",
                            configuration[:too_few_words],
                           :'activerecord.errors.messages.too_few_words'])
           record.errors.add(attr_name, message)
        end
            
        end # validates_each
      end # validates_at_least_one

    end    
  end
end
