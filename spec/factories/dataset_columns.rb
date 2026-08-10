FactoryBot.define do
  factory :dataset_column do
    dataset
    sequence(:name) { |n| "column_#{n}" }
    sequence(:display_name) { |n| "Column #{n}" }
    data_type { "string" }
    sequence(:position) { |n| n }
  end
end
