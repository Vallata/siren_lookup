require 'roo'
require 'httparty'
require 'caxlsx'

class SirenLookupService
  API_URL = "https://recherche-entreprises.api.gouv.fr/search"

  def initialize(file_path)
    @file_path = file_path
  end

  def perform
    xlsx = Roo::Excelx.new(@file_path)
    sheet = xlsx.sheet(0)

    results = [["Nom entreprise", "SIREN"]] # en-tête de la nouvelle feuille

    sheet.each_row_streaming(offset: 1) do |row|
      name = row[0]&.cell_value.to_s.strip
      next if name.empty?

      puts "Recherche : #{name}"
      siren = fetch_siren(name)
      results << [name, siren]

      sleep 1
    end

    save_to_excel(results)
  end

  private

  def fetch_siren(name)
    response = HTTParty.get(API_URL, query: { q: name })
    data = response.parsed_response

    first = data.dig("results", 0)
    first&.dig("siren") || "Non trouvé"
  rescue => e
    puts "Erreur API pour #{name} : #{e.message}"
    "Erreur"
  end

  def save_to_excel(data)
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    output_path = "tmp/results/siren_result_#{timestamp}.xlsx"

    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: "Résultats") do |sheet|
        data.each { |row| sheet.add_row row }
      end
      p.serialize(output_path)
    end

    output_path
  end
end
