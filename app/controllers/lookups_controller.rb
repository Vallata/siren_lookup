class LookupsController < ApplicationController
  def index
  end

  def upload
    return redirect_to root_path if params[:lookup].nil?

    uploaded_file = params[:lookup][:file]

    # Sauvegarde temporaire du fichier
    input_path = Rails.root.join('tmp', 'uploads', uploaded_file.original_filename)
    FileUtils.mkdir_p(File.dirname(input_path))
    File.open(input_path, 'wb') { |f| f.write(uploaded_file.read) }

    # Récupération des champs sélectionnés par l'utilisateur
    selected_fields = params[:fields].select { |key, value| value == '1' }.keys

    # Appel du traitement
    output_path = process_excel_file(input_path, selected_fields)

    # Enregistrement du chemin pour la vue
    session[:download_path] = output_path.relative_path_from(Rails.root.join('public'))

    redirect_to result_lookups_path
  end

  def result
    @download_link = "/#{session[:download_path]}"
  end

  private

  def process_excel_file(input_path, selected_fields)
    require 'write_xlsx'
    require 'roo'
    require 'net/http'
    require 'uri'
    require 'json'

    workbook = Roo::Spreadsheet.open(input_path.to_s)
    sheet = workbook.sheet(0)

    output_path = Rails.root.join('public', 'downloads', "result_#{Time.now.to_i}.xlsx")
    FileUtils.mkdir_p(File.dirname(output_path))
    workbook_out = WriteXLSX.new(output_path.to_s)
    worksheet = workbook_out.add_worksheet

    # En-têtes
    headers = ["Nom d'entreprise"]
    headers << "SIREN" if selected_fields.include?("siren")
    headers << "Adresse" if selected_fields.include?("adresse")
    headers << "Nature juridique" if selected_fields.include?("nature_juridique")
    headers << "Code NAF" if selected_fields.include?("code_naf")
    headers.each_with_index { |header, i| worksheet.write(0, i, header) }

    # Traitement ligne par ligne
    sheet.each_with_index do |row, i|
      next if i == 0 # ignorer l'en-tête

      nom = row[0].to_s.strip
      next if nom.empty?

      api_data = fetch_full_data_from_api(nom)
      row_data = [nom]

      if selected_fields.include?("siren")
        row_data << (api_data["siren"] || "Non trouvé")
      end

      if selected_fields.include?("adresse")
        row_data << (api_data.dig("siege", "geo_adresse") || "Non trouvée")
      end

      if selected_fields.include?("nature_juridique")
        row_data << (api_data["nature_juridique"] || "Non trouvée")
      end

      if selected_fields.include?("code_naf")
        row_data << (api_data["activite_principale"] || "Non trouvé")
      end

      row_data.each_with_index { |data, j| worksheet.write(i + 1, j, data) }
      sleep 0.5
    end

    workbook_out.close
    return output_path
  end

  def fetch_full_data_from_api(nom)
    uri = URI("https://recherche-entreprises.api.gouv.fr/search?q=#{URI.encode_www_form_component(nom)}")
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      json = JSON.parse(response.body)
      return json["results"]&.first || {}
    else
      return {}
    end
  end

end
