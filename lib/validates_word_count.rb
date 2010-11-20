module ActiveRecord
  module Validations
    module ClassMethods

      def validates_word_count(*args)
        configuration = {
                          # :too_few_words  => I18n.translate('validates_word_count.errors.messages.too_few_words'),
                          # :too_many_words => I18n.translate('validates_word_count.errors.messages.too_many_words'),
                          :too_few_words  => "has too few words (minimum is %d words)",
                          :too_many_words => "has too many words (maximum is %d words)",
                          :on => :save, :with => nil
                        }
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
        
        too_few_words  = configuration[:too_few_words]  % minimum unless minimum.nil?
        too_many_words = configuration[:too_many_words] % maximum unless maximum.nil?

        validates_each(args, configuration) do |record, attr_name, value|
          next if value.nil?

          # remove HTML tags; convert HTML entities to spaces; remove punctuation
          cleaned_text = value.gsub(/<.[^<>]*?>/, ' ').gsub(/&nbsp;|&#160;/i, ' ').gsub(/[.(),;:!?%#$'"_+=\/-]*/,'')
          word_count = cleaned_text.scan(/[\w-]+/).size
                    
          unless maximum.nil?
            record.errors.add(attr_name, too_many_words) if word_count > maximum
          end

          unless minimum.nil?
            record.errors.add(attr_name, too_few_words) if word_count < minimum
          end
            
        end # validates_each
      end # validates_at_least_one

    end    
  end
end
