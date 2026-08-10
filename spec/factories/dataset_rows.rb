FactoryBot.define do
  factory :dataset_row do
    dataset
    data { { "column_1" => "value" } }
  end
end
