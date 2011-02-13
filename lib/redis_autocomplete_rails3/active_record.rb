module RedisAutocompleteRails3
  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    # Usage:
    #   redis_autocomplete :title
    def redis_autocomplete(*fields)
      # todo: make sure fields are all valid
      cattr_accessor :redis_autocomplete_set_prefix, :redis_autocomplete_fields, :redis_autocompleter
      opts = fields.extract_options!
      self.redis_autocomplete_set_prefix = opts.delete(:set_prefix) || 'redis_autocomplete_rails3'
      
      self.redis_autocomplete_fields = Hash[fields.map do |field|
        set_name = "#{self.redis_autocomplete_set_prefix}_#{model_name.underscore}_#{field}"

        self.instance_eval %{
          def suggest_#{field}(term, count = 10)
            self.redis_autocompleter.suggest(term, count, "#{set_name}")
          end
        }

        [field, set_name]
      end]
      self.redis_autocompleter = RedisAutocomplete.new(opts)

      before_save :update_redis_autocompletion_entry
      after_destroy :remove_redis_autocompletion_entry

      send :include, InstanceMethods
    end
  end

  module InstanceMethods
    def update_redis_autocompletion_entry
      r = self.class.redis_autocompleter
      self.class.redis_autocomplete_fields.each_pair do |field, set_name|
        f = self[field]
        if self.send "#{field}_changed?"
          r.remove_word(f, set_name) if persisted?
          r.add_word(f, set_name)
        end
      end
    end

    def remove_redis_autocompletion_entry
      r = self.class.redis_autocompleter
      self.class.redis_autocomplete_fields.each_pair do |field, set_name|
        r.remove_word(self[field], set_name)
      end
    end

    # todo: add suggest_[:field] methods for each autocomplete field
    # todo: define autocomplete helper if not defined
  end
end

ActiveRecord::Base.send :include, RedisAutocompleteRails3
