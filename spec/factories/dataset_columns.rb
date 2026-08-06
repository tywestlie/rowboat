FactoryBot.define do
  factory :dataset_column do
    dataset { nil }
    name { "MyString" }
    display_name { "MyString" }
    data_type { "MyString" }
    position { 1 }
  end
end
