FactoryBot.define do
  factory :stellar_host do
    sequence(:hostname) { |n| "Host #{n}" }
    st_spectype { "G2 V" }
    st_teff { 5000.0 }
    st_rad { 1.0 }
    st_mass { 1.0 }
    st_met { 0.0 }
    st_lum { 0.0 }
    sy_dist { 100.0 }
    ra { 180.0 }
    dec { 0.0 }
  end
end
