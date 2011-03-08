Dir[File.join("#{File.dirname(__FILE__)}/config/locales/*.yml")].each do |locale|
  I18n.load_path.unshift(locale)
end

require File.join(File.dirname(__FILE__), 'lib/validates_word_count')
