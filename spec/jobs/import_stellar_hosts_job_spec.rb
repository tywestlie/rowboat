require "rails_helper"

RSpec.describe ImportStellarHostsJob, type: :job do
  let(:csv_body) do
    <<~CSV
      hostname,st_spectype,st_teff,st_rad,st_mass,st_met,st_lum,sy_dist,ra,dec
      Kepler-442,K5 V,4402,0.60,0.61,-0.37,-1.202,370.6,285.6,39.28
      Proxima Centauri,M5.5 Ve,3050,0.15,0.12,0.15,-2.85,1.30,217.4,-62.68
    CSV
  end

  def stub_fetch(success:, code:, body: "")
    response = instance_double(success ? Net::HTTPOK : Net::HTTPNotFound, code: code, body: body)
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(success)
    allow(Net::HTTP).to receive(:get_response)
      .with(URI(ImportStellarHostsJob::STELLAR_HOSTS_URL))
      .and_return(response)
  end

  context "when the fetch succeeds" do
    before { stub_fetch(success: true, code: "200", body: csv_body) }

    it "creates the Stellar Hosts dataset with its source url" do
      described_class.perform_now

      dataset = Dataset.find_by(name: "Stellar Hosts")
      expect(dataset).to be_present
      expect(dataset.source_url).to eq(ImportStellarHostsJob::STELLAR_HOSTS_URL)
    end

    it "creates a dataset column for every column definition, in order" do
      described_class.perform_now

      dataset = Dataset.find_by!(name: "Stellar Hosts")
      columns = dataset.dataset_columns.order(:position)

      expect(columns.pluck(:name)).to eq(ImportStellarHostsJob::COLUMN_DEFS.keys)
      expect(columns.first).to have_attributes(
        display_name: "Host Star",
        data_type: "string",
        position: 0
      )
      expect(columns.last).to have_attributes(
        display_name: "Declination",
        data_type: "float",
        position: 9
      )
    end

    it "stores each CSV row as jsonb data keyed by column name" do
      described_class.perform_now

      dataset = Dataset.find_by!(name: "Stellar Hosts")
      row = dataset.dataset_rows.find_by("data ->> 'hostname' = ?", "Kepler-442")

      expect(row.data).to eq(
        "hostname" => "Kepler-442",
        "st_spectype" => "K5 V",
        "st_teff" => "4402",
        "st_rad" => "0.60",
        "st_mass" => "0.61",
        "st_met" => "-0.37",
        "st_lum" => "-1.202",
        "sy_dist" => "370.6",
        "ra" => "285.6",
        "dec" => "39.28"
      )
    end

    it "sets imported_at and row_count on the dataset" do
      described_class.perform_now

      dataset = Dataset.find_by!(name: "Stellar Hosts")
      expect(dataset.imported_at).to be_within(5.seconds).of(Time.current)
      expect(dataset.row_count).to eq(2)
    end

    it "replaces existing rows and columns on re-import instead of duplicating them" do
      described_class.perform_now
      dataset = Dataset.find_by!(name: "Stellar Hosts")
      original_dataset_id = dataset.id

      stub_fetch(success: true, code: "200", body: <<~CSV)
        hostname,st_spectype,st_teff,st_rad,st_mass,st_met,st_lum,sy_dist,ra,dec
        TRAPPIST-1,M8 V,2559,0.12,0.09,0.04,-3.29,12.43,346.6,-5.04
      CSV
      described_class.perform_now

      expect(Dataset.where(name: "Stellar Hosts").count).to eq(1)
      dataset.reload
      expect(dataset.id).to eq(original_dataset_id)
      expect(dataset.dataset_columns.count).to eq(ImportStellarHostsJob::COLUMN_DEFS.size)
      expect(dataset.dataset_rows.count).to eq(1)
      expect(dataset.row_count).to eq(1)
      expect(dataset.dataset_rows.first.data["hostname"]).to eq("TRAPPIST-1")
    end

    context "and the CSV has multiple rows for the same hostname" do
      before { stub_fetch(success: true, code: "200", body: <<~CSV) }
        hostname,st_spectype,st_teff,st_rad,st_mass,st_met,st_lum,sy_dist,ra,dec
        HD 80653,,5959,1.199,1.150,0.255,,109.86,140.339,14.368
        HD 80653,G0 V,,1.199,1.150,0.255,-1.05,109.86,140.339,14.368
        HD 80653,,6080,,,,,109.86,140.339,14.368
      CSV

      it "keeps only the row with the fewest blank fields per hostname" do
        described_class.perform_now

        dataset = Dataset.find_by!(name: "Stellar Hosts")
        expect(dataset.dataset_rows.count).to eq(1)
        expect(dataset.row_count).to eq(1)
        expect(dataset.dataset_rows.first.data).to include(
          "st_spectype" => "G0 V",
          "st_lum" => "-1.05"
        )
      end
    end

    context "and the CSV has no data rows" do
      before { stub_fetch(success: true, code: "200", body: "hostname,st_spectype,st_teff,st_rad,st_mass,st_met,st_lum,sy_dist,ra,dec\n") }

      it "creates the dataset with zero rows" do
        described_class.perform_now

        dataset = Dataset.find_by!(name: "Stellar Hosts")
        expect(dataset.dataset_rows.count).to eq(0)
        expect(dataset.row_count).to eq(0)
      end
    end
  end

  context "when the fetch fails" do
    before { stub_fetch(success: false, code: "404") }

    it "raises an error and does not create a dataset" do
      expect { described_class.perform_now }.to raise_error(RuntimeError, "Fetch failed: 404")
      expect(Dataset.where(name: "Stellar Hosts")).not_to exist
    end
  end
end
