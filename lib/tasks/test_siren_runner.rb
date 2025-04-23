require_relative '../../app/services/siren_lookup_service'

file_path = "tmp/uploads/test.xlsx" # Ton fichier avec noms d’entreprises
result_path = SirenLookupService.new(file_path).perform

puts "✅ Fichier généré : #{result_path}"
