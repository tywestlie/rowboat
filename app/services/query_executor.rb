# Runs a validated structured query end-to-end and returns a shape-tagged
# result, so callers (the answer job, and the show page on reload) can
# render it consistently without duplicating aggregate/group logic.
class QueryExecutor
  Result = Struct.new(:kind, :value, :rows, :group_by_field, keyword_init: true)

  def self.call(structured_query)
    translator = QueryTranslator.new(structured_query)
    relation = translator.translate

    if translator.aggregate
      value = run_aggregate(relation, translator.aggregate)

      if translator.group_by
        Result.new(kind: :chart, rows: value, group_by_field: translator.group_by)
      else
        Result.new(kind: :value, value: value)
      end
    else
      Result.new(kind: :table, rows: relation.to_a)
    end
  end

  def self.run_aggregate(relation, aggregate)
    function = aggregate["function"]
    field = aggregate["field"]

    if function == "count"
      field.present? ? relation.count(field.to_sym) : relation.count
    else
      relation.send(function, field.to_sym)
    end
  end
end
