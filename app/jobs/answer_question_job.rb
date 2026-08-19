class AnswerQuestionJob < ApplicationJob
  queue_as :default

  QUERY_TOOL_NAME = "generate_structured_query"

  MODEL = "claude-opus-4-6"

  def perform(query)
    structured_query = generate_structured_query(query.question)
    result = QueryExecutor.call(structured_query)
    summary = generate_summary(query.question, result)

    query.update!(generated_query: structured_query, result_summary: summary)
    broadcast_result(query, result)
  rescue StandardError => e
    Rails.logger.error("AnswerQuestionJob failed for query #{query.id}: #{e.class}: #{e.message}")
    query.update!(result_summary: "Sorry, something went wrong answering that question. Please try rephrasing it.")
    broadcast_error(query)
  end

  private

  def client
    @client ||= Anthropic::Client.new(api_key: AiCredentials.anthropic_api_key)
  end

  def generate_structured_query(question)
    message = client.messages.create(
      model: MODEL,
      max_tokens: 1024,
      system: <<~SYSTEM,
        You translate natural-language questions about exoplanets and their host
        stars into a structured query. Only use these models and fields:

        #{QueryableFields.schema_description}

        Use the #{QUERY_TOOL_NAME} tool to respond. Always pick "model" as either
        "Exoplanet" or "StellarHost". Only reference fields listed above.
      SYSTEM
      messages: [ { role: "user", content: question } ],
      tools: [ query_tool ],
      tool_choice: { type: "tool", name: QUERY_TOOL_NAME }
    )

    tool_use = message.content.find { |block| block.type == :tool_use }
    raise "Claude did not return a structured query" unless tool_use

    tool_use.input.deep_stringify_keys
  end

  def generate_summary(question, result)
    message = client.messages.create(
      model: MODEL,
      max_tokens: 512,
      messages: [
        {
          role: "user",
          content: <<~PROMPT
            Question: #{question}

            Query result: #{result_for_prompt(result)}

            Write a short, plain-English answer to the question based on this result.
            Do not mention the underlying query or database.
          PROMPT
        }
      ]
    )

    text_block = message.content.find { |block| block.type == :text }
    text_block&.text.presence || "No summary could be generated."
  end

  def result_for_prompt(result)
    case result.kind
    when :value
      result.value.to_s
    when :chart
      result.rows.first(50).to_h.to_s
    when :table
      result.rows.first(20).map(&:attributes).to_s
    end
  end

  def query_tool
    {
      name: QUERY_TOOL_NAME,
      description: "Translate a natural-language question about exoplanets or stellar hosts into a structured query.",
      input_schema: {
        type: "object",
        properties: {
          model: { type: "string", enum: QueryableFields.model_names },
          filters: {
            type: "array",
            items: {
              type: "object",
              properties: {
                field: { type: "string" },
                operator: { type: "string", enum: QueryableFields::OPERATORS },
                value: {}
              },
              required: %w[field operator value]
            }
          },
          aggregate: {
            type: [ "object", "null" ],
            properties: {
              function: { type: "string", enum: QueryableFields::AGGREGATE_FUNCTIONS },
              field: { type: [ "string", "null" ] }
            },
            required: [ "function" ]
          },
          group_by: { type: [ "string", "null" ] },
          sort: {
            type: [ "object", "null" ],
            properties: {
              field: { type: "string" },
              direction: { type: "string", enum: %w[asc desc] }
            },
            required: %w[field direction]
          },
          limit: { type: [ "integer", "null" ] }
        },
        required: %w[model filters]
      }
    }
  end

  def broadcast_result(query, result)
    query.broadcast_replace_to(
      query,
      target: ActionView::RecordIdentifier.dom_id(query, :answer),
      partial: "questions/answer",
      locals: { query: query, result: result }
    )
  end

  def broadcast_error(query)
    query.broadcast_replace_to(
      query,
      target: ActionView::RecordIdentifier.dom_id(query, :answer),
      partial: "questions/error",
      locals: { query: query }
    )
  end
end
