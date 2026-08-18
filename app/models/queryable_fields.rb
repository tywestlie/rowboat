module QueryableFields
  MODELS = {
    "Exoplanet" => Exoplanet,
    "StellarHost" => StellarHost
  }.freeze

  EXCLUDED_COLUMNS = %w[id created_at updated_at].freeze

  OPERATORS = %w[= != > >= < <=].freeze

  AGGREGATE_FUNCTIONS = %w[count avg min max sum].freeze

  class << self
    def model_names
      MODELS.keys
    end

    def model_for(name)
      MODELS[name]
    end

    def valid_model?(name)
      MODELS.key?(name)
    end

    def fields_for(model_name)
      model = model_for(model_name)
      return [] unless model

      excluded = EXCLUDED_COLUMNS + foreign_keys_for(model)
      model.column_names - excluded
    end

    def valid_field?(model_name, field)
      fields_for(model_name).include?(field.to_s)
    end

    def valid_operator?(operator)
      OPERATORS.include?(operator.to_s)
    end

    def valid_aggregate_function?(function)
      AGGREGATE_FUNCTIONS.include?(function.to_s)
    end

    # Plain-text description of the whitelisted schema, for prompting the LLM.
    # Built from the whitelist itself, not raw DB introspection, so it can
    # never describe a field the translator would go on to reject.
    def schema_description
      model_names.map do |name|
        "#{name}: #{fields_for(name).join(', ')}"
      end.join("\n")
    end

    private

    def foreign_keys_for(model)
      model.reflect_on_all_associations(:belongs_to).map(&:foreign_key)
    end
  end
end
