module DatasetsHelper
  def has_hostname_column?(columns)
    columns.map(&:name).include?("hostname")
  end
end
