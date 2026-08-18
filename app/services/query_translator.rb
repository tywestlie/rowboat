# Translates a structured query hash (as produced by the LLM tool call) into
# a real ActiveRecord relation. Every field, operator, and aggregate function
# is checked against QueryableFields before it touches the database; nothing
# from the hash is ever interpolated into SQL text.
class QueryTranslator
  class InvalidQueryError < StandardError; end

  OPERATOR_METHODS = {
    "=" => :eq,
    "!=" => :not_eq,
    ">" => :gt,
    ">=" => :gteq,
    "<" => :lt,
    "<=" => :lteq
  }.freeze

  DIRECTIONS = %w[asc desc].freeze

  attr_reader :model, :aggregate, :group_by

  def initialize(structured_query)
    @query = structured_query.deep_stringify_keys
    @model = validated_model
    @aggregate = validated_aggregate
    @group_by = validated_group_by
  end

  # Builds the relation with filters, group, sort, and limit applied.
  # Aggregate functions are validated here but executed by the caller
  # against the returned relation (relation.sum(:field), etc.), since
  # calling them here would return a scalar/hash instead of a relation.
  def translate
    relation = model.all
    relation = apply_filters(relation)
    relation = apply_group(relation)
    relation = apply_sort(relation)
    relation = apply_limit(relation)
    relation
  end

  private

  def validated_model
    model_name = @query["model"]
    unless QueryableFields.valid_model?(model_name)
      raise InvalidQueryError, "Unknown model: #{model_name.inspect}"
    end

    QueryableFields.model_for(model_name)
  end

  def validated_field!(field)
    unless QueryableFields.valid_field?(@query["model"], field)
      raise InvalidQueryError, "Field not whitelisted: #{field.inspect}"
    end

    field.to_s
  end

  def validated_aggregate
    aggregate = @query["aggregate"]
    return nil if aggregate.nil?

    aggregate = aggregate.stringify_keys
    function = aggregate["function"]
    unless QueryableFields.valid_aggregate_function?(function)
      raise InvalidQueryError, "Aggregate function not whitelisted: #{function.inspect}"
    end

    field = aggregate["field"]
    if field.present?
      validated_field!(field)
    elsif function != "count"
      raise InvalidQueryError, "Aggregate function #{function.inspect} requires a field"
    end

    { "function" => function, "field" => field }
  end

  def validated_group_by
    group_by = @query["group_by"]
    return nil if group_by.blank?

    validated_field!(group_by)
  end

  def apply_filters(relation)
    filters = Array(@query["filters"])
    filters.reduce(relation) do |rel, filter|
      filter = filter.stringify_keys
      field = validated_field!(filter["field"])
      operator = filter["operator"]

      unless QueryableFields.valid_operator?(operator)
        raise InvalidQueryError, "Operator not whitelisted: #{operator.inspect}"
      end

      arel_method = OPERATOR_METHODS.fetch(operator)
      condition = model.arel_table[field].public_send(arel_method, filter["value"])
      rel.where(condition)
    end
  end

  def apply_group(relation)
    return relation unless group_by

    relation.group(group_by)
  end

  def apply_sort(relation)
    sort = @query["sort"]
    return relation if sort.blank?

    sort = sort.stringify_keys
    field = validated_field!(sort["field"])
    direction = sort["direction"].to_s

    unless DIRECTIONS.include?(direction)
      raise InvalidQueryError, "Sort direction not whitelisted: #{direction.inspect}"
    end

    relation.order(field => direction.to_sym)
  end

  def apply_limit(relation)
    limit = @query["limit"]
    return relation if limit.blank?

    limit = Integer(limit, exception: false)
    raise InvalidQueryError, "Limit must be an integer: #{@query['limit'].inspect}" if limit.nil?

    relation.limit(limit)
  end
end
