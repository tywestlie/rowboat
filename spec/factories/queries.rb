FactoryBot.define do
  factory :query do
    question { "How many exoplanets were discovered after 2015?" }
    generated_query { nil }
    result_summary { nil }
  end
end
