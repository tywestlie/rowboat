module ExoplanetsHelper
  EXOPLANET_COLUMNS = [
    { name: :pl_name, label: "Planet Name", numeric: false },
    { name: :hostname, label: "Host Star", numeric: false },
    { name: :discoverymethod, label: "Discovery Method", numeric: false },
    { name: :disc_year, label: "Discovery Year", numeric: true },
    { name: :pl_orbper, label: "Orbital Period (days)", numeric: true },
    { name: :pl_rade, label: "Radius (Earth radii)", numeric: true },
    { name: :pl_bmasse, label: "Mass (Earth masses)", numeric: true },
    { name: :pl_eqt, label: "Equilibrium Temp (K)", numeric: true },
    { name: :st_teff, label: "Host Star Temp (K)", numeric: true },
    { name: :sy_dist, label: "Distance (parsecs)", numeric: true }
  ].freeze
end
