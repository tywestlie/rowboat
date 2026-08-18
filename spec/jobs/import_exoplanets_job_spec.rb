require "rails_helper"

RSpec.describe ImportExoplanetsJob, type: :job do
  let(:csv_body) do
    <<~CSV
      pl_name,hostname,discoverymethod,disc_year,pl_orbper,pl_rade,pl_bmasse,pl_eqt,st_teff,sy_dist
      Kepler-442 b,Kepler-442,Transit,2015,112.3,1.34,2.36,233,4402,370.6
      Proxima Centauri b,Proxima Centauri,Radial Velocity,2016,11.2,1.07,1.27,234,3050,1.30
    CSV
  end

  def stub_fetch(success:, code:, body: "")
    response = instance_double(success ? Net::HTTPOK : Net::HTTPNotFound, code: code, body: body)
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(success)
    allow(Net::HTTP).to receive(:get_response)
      .with(URI(ImportExoplanetsJob::EXOPLANET_URL))
      .and_return(response)
  end

  context "when the fetch succeeds" do
    before { stub_fetch(success: true, code: "200", body: csv_body) }

    it "creates the Confirmed Exoplanets dataset with its source url" do
      described_class.perform_now

      dataset = Dataset.find_by(name: "Confirmed Exoplanets")
      expect(dataset).to be_present
      expect(dataset.source_url).to eq(ImportExoplanetsJob::EXOPLANET_URL)
    end

    it "creates a typed Exoplanet row for each CSV row with numeric fields cast" do
      described_class.perform_now

      exoplanet = Exoplanet.find_by(pl_name: "Kepler-442 b")

      expect(exoplanet).to have_attributes(
        hostname: "Kepler-442",
        discoverymethod: "Transit",
        disc_year: 2015,
        pl_orbper: 112.3,
        pl_rade: 1.34,
        pl_bmasse: 2.36,
        pl_eqt: 233.0,
        st_teff: 4402.0,
        sy_dist: 370.6
      )
    end

    it "sets imported_at and row_count on the dataset" do
      described_class.perform_now

      dataset = Dataset.find_by!(name: "Confirmed Exoplanets")
      expect(dataset.imported_at).to be_within(5.seconds).of(Time.current)
      expect(dataset.row_count).to eq(2)
    end

    it "replaces existing rows on re-import instead of duplicating them" do
      described_class.perform_now
      dataset = Dataset.find_by!(name: "Confirmed Exoplanets")
      original_dataset_id = dataset.id

      stub_fetch(success: true, code: "200", body: <<~CSV)
        pl_name,hostname,discoverymethod,disc_year,pl_orbper,pl_rade,pl_bmasse,pl_eqt,st_teff,sy_dist
        TRAPPIST-1 e,TRAPPIST-1,Transit,2017,6.1,0.92,0.69,251,2559,12.43
      CSV
      described_class.perform_now

      expect(Dataset.where(name: "Confirmed Exoplanets").count).to eq(1)
      dataset.reload
      expect(dataset.id).to eq(original_dataset_id)
      expect(Exoplanet.count).to eq(1)
      expect(dataset.row_count).to eq(1)
      expect(Exoplanet.first.pl_name).to eq("TRAPPIST-1 e")
    end

    context "and the CSV has no data rows" do
      before { stub_fetch(success: true, code: "200", body: "pl_name,hostname,discoverymethod,disc_year,pl_orbper,pl_rade,pl_bmasse,pl_eqt,st_teff,sy_dist\n") }

      it "creates the dataset with zero rows" do
        described_class.perform_now

        dataset = Dataset.find_by!(name: "Confirmed Exoplanets")
        expect(Exoplanet.count).to eq(0)
        expect(dataset.row_count).to eq(0)
      end
    end
  end

  context "when the fetch fails" do
    before { stub_fetch(success: false, code: "404") }

    it "raises an error and does not create a dataset" do
      expect { described_class.perform_now }.to raise_error(RuntimeError, "Fetch failed: 404")
      expect(Dataset.where(name: "Confirmed Exoplanets")).not_to exist
    end
  end
end
