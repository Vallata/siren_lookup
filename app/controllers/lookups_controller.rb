class LookupsController < ApplicationController
  def index
  end

  def upload
    uploaded_file = params[:lookup][:file]
    return redirect_to root_path, alert: "Aucun fichier fourni." if uploaded_file.nil?

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

    # Lire le fichier original
    workbook = Roo::Spreadsheet.open(input_path.to_s)
    sheet = workbook.sheet(0)

    # Créer un nouveau fichier Excel
    output_path = Rails.root.join('public', 'downloads', "result_#{Time.now.to_i}.xlsx")
    FileUtils.mkdir_p(File.dirname(output_path))
    workbook_out = WriteXLSX.new(output_path.to_s)
    worksheet = workbook_out.add_worksheet

    # En-têtes dynamiques en fonction des champs sélectionnés
    headers = ["Nom d'entreprise"]
    headers << "SIREN" if selected_fields.include?("siren")
    headers << "Adresse" if selected_fields.include?("adresse")
    headers << "Raison sociale" if selected_fields.include?("raison_sociale")
    headers << "Nature juridique" if selected_fields.include?("nature_juridique")
    headers << "Capital social" if selected_fields.include?("capital_social")
    headers << "Code NAF" if selected_fields.include?("code_naf")

    # Écrire les en-têtes
    headers.each_with_index { |header, i| worksheet.write(0, i, header) }

    # Traiter chaque ligne
    sheet.each_with_index do |row, i|
      next if i == 0 # ignorer l'en-tête si présent

      nom = row[0].to_s.strip
      next if nom.empty?

      # Initialiser les données à insérer dans la ligne
      row_data = [nom]
      row_data << fetch_siren_from_api(nom) if selected_fields.include?("siren")
      row_data << fetch_adresse_from_api(nom) if selected_fields.include?("adresse")
      row_data << fetch_raison_sociale_from_api(nom) if selected_fields.include?("raison_sociale")
      row_data << fetch_nature_juridique_from_api(nom) if selected_fields.include?("nature_juridique")
      row_data << fetch_code_naf_from_api(nom) if selected_fields.include?("code_naf")

      # Écrire les données dans le fichier
      row_data.each_with_index { |data, j| worksheet.write(i + 1, j, data || "Non trouvé") }

      sleep 0.5 # respecter le délai entre requêtes
    end

    workbook_out.close
    return output_path
  end

  def fetch_siren_from_api(nom)
    url = URI("https://recherche-entreprises.api.gouv.fr/search?q=#{URI.encode_www_form_component(nom)}")
    response = Net::HTTP.get_response(url)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      # Vérifier si des résultats sont retournés
      first_result = data["results"]&.first
      if first_result
        return first_result["siren"] # Extraire le SIREN du premier résultat
      end
    end

    nil
  end


  def fetch_adresse_from_api(nom)
    url = URI("https://recherche-entreprises.api.gouv.fr/search?q=#{URI.encode_www_form_component(nom)}")
    response = Net::HTTP.get_response(url)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      first_result = data["results"]&.first
      if first_result && first_result["siege"]
        return first_result["siege"]["adresse"] # Extraire l'adresse du siège
      end
    end

    nil
  end


  def fetch_raison_sociale_from_api(nom)
    url = URI("https://recherche-entreprises.api.gouv.fr/search?q=#{URI.encode_www_form_component(nom)}")
    response = Net::HTTP.get_response(url)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      first_result = data["results"]&.first
      if first_result
        return first_result["nom_raison_sociale"] # Extraire la raison sociale
      end
    end

    nil
  end

  def fetch_nature_juridique_from_api(nom)
    url = URI("https://recherche-entreprises.api.gouv.fr/search?q=#{URI.encode_www_form_component(nom)}")
    response = Net::HTTP.get_response(url)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      # Vérifier si des résultats sont retournés
      first_result = data["results"]&.first
      if first_result
        return first_result["nature_juridique"] # Extraire le SIREN du premier résultat
      end
    end

    nil
  end


  # def fetch_forme_juridique_from_api(nom)
  #   url = URI("https://recherche-entreprises.api.gouv.fr/search?q=#{URI.encode_www_form_component(nom)}")
  #   response = Net::HTTP.get_response(url)

  #   if response.is_a?(Net::HTTPSuccess)
  #     data = JSON.parse(response.body)
  #     first = data["results"]&.first
  #     return first["forme_juridique"] if first
  #   end

  #   nil
  # end

  # def fetch_capital_social_from_api(nom)
  #   url = URI("https://recherche-entreprises.api.gouv.fr/search?q=#{URI.encode_www_form_component(nom)}")
  #   response = Net::HTTP.get_response(url)

  #   if response.is_a?(Net::HTTPSuccess)
  #     data = JSON.parse(response.body)
  #     first_result = data["results"]&.first
  #     if first_result && first_result["siege"]
  #       return first_result["siege"]["capital_social"] # Extraire le capital social du siège
  #     end
  #   end

  #   nil
  # end


  def fetch_code_naf_from_api(nom)
    url = URI("https://recherche-entreprises.api.gouv.fr/search?q=#{URI.encode_www_form_component(nom)}")
    response = Net::HTTP.get_response(url)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      first_result = data["results"]&.first
      if first_result
        return first_result["activite_principale"] # Extraire le code NAF
      end
    end

    nil
  end

end
