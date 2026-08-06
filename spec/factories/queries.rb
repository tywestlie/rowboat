FactoryBot.define do
  factory :query do
    dataset { nil }
    question { "MyText" }
    generated_query { "" }
    result_summary { "MyText" }
  end
end
