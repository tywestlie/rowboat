require "rails_helper"

RSpec.describe AnswerQuestionJob, type: :job do
  let(:query) { create(:query, question: "How many exoplanets were discovered after 2015?") }
  let(:client) { instance_double(Anthropic::Client, messages: messages) }
  let(:messages) { instance_double(Anthropic::Resources::Messages) }

  before do
    allow(Anthropic::Client).to receive(:new).and_return(client)
  end

  def tool_use_response(input)
    block = instance_double(Anthropic::Models::ToolUseBlock, type: :tool_use, input: input)
    instance_double(Anthropic::Models::Message, content: [ block ])
  end

  def text_response(text)
    block = instance_double(Anthropic::Models::TextBlock, type: :text, text: text)
    instance_double(Anthropic::Models::Message, content: [ block ])
  end

  context "when the API calls succeed" do
    before do
      create(:exoplanet, disc_year: 2018)
      create(:exoplanet, disc_year: 2005)

      allow(messages).to receive(:create).and_return(
        tool_use_response({ "model" => "Exoplanet", "filters" => [ { "field" => "disc_year", "operator" => ">", "value" => 2015 } ] }),
        text_response("One exoplanet was discovered after 2015.")
      )
    end

    it "saves the generated query and the plain-English summary" do
      described_class.perform_now(query)
      query.reload

      expect(query.generated_query).to eq(
        "model" => "Exoplanet",
        "filters" => [ { "field" => "disc_year", "operator" => ">", "value" => 2015 } ]
      )
      expect(query.result_summary).to eq("One exoplanet was discovered after 2015.")
    end
  end

  context "when the model returns a structured query outside the whitelist" do
    before do
      allow(messages).to receive(:create).and_return(
        tool_use_response({ "model" => "User", "filters" => [] })
      )
    end

    it "saves a friendly error message instead of raising" do
      expect { described_class.perform_now(query) }.not_to raise_error
      query.reload

      expect(query.generated_query).to be_nil
      expect(query.result_summary).to include("Sorry, something went wrong")
    end
  end

  context "when the API call itself fails" do
    before do
      allow(messages).to receive(:create).and_raise(Anthropic::Errors::APIConnectionError.new(url: URI("https://api.anthropic.com")))
    end

    it "saves a friendly error message instead of raising" do
      expect { described_class.perform_now(query) }.not_to raise_error
      query.reload

      expect(query.result_summary).to include("Sorry, something went wrong")
    end
  end
end
