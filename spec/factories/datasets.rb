FactoryBot.define do
  factory :dataset do
    sequence(:name) { |n| "Dataset #{n}" }
    source_url { "MyString" }
    imported_at { "2026-08-06 13:17:41" }
    row_count { 1 }
  end
end
