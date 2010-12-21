module ActiveRecord
  module Validations
    module ClassMethods

      def validates_word_count(*args)
        configuration = { :on => :save, :with => nil}
        configuration.update(args.pop) if args.last.is_a?(Hash)

        maximum = minimum = nil

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
          
          # remove HTML tags; convert HTML entities to spaces; remove punctuation
          cleaned_text = value.gsub(/<.[^<>]*?>/, ' ').gsub(/&nbsp;|&#160;/i, ' ').gsub(/[.(),;:!?%#$'"_+=\/-]*/,'')
          word_count = cleaned_text.scan(/[\w-]+/).size
          
          # to determine the error message:
          # - look for a translation of something attribute-sepecific (likely in the app's en.yml)
          # - look for a translation of something model-sepecific (likely in the app's en.yml)
          # - look for something passed in as a parameter (:too_many_words => "")
          # - look for a translation of the default error message (likely in the plugin's en.yml)
          if !maximum.nil? and (word_count > maximum)
            message = I18n.t("activerecord.errors.models.#{name.underscore}.attributes.#{attr_name}.too_many_words", :words => maximum,
                        :default => [:"activerecord.errors.models.#{name.underscore}.too_many_words",
                                    configuration[:too_many_words],
                                    :'activerecord.errors.messages.too_many_words'])
            record.errors.add(attr_name, message)

          elsif !minimum.nil? and (word_count < minimum)
            message = I18n.t("activerecord.errors.models.#{name.underscore}.attributes.#{attr_name}.too_few_words", :words => minimum,
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
