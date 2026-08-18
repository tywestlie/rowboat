FactoryBot.define do
  factory :exoplanet do
    sequence(:pl_name) { |n| "Planet #{n}" }
    sequence(:hostname) { |n| "Host #{n}" }
    discoverymethod { "Transit" }
    disc_year { 2020 }
    pl_orbper { 10.5 }
    pl_rade { 1.5 }
    pl_bmasse { 2.5 }
    pl_eqt { 300.0 }
    st_teff { 5000.0 }
    sy_dist { 100.0 }
  end
end
