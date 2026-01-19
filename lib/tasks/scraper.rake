require_relative '../scrapers/avocat_scraper'

namespace :scraper do
  desc "Scraper les avocats et exporter en CSV"
  task :avocats do
    url = ENV['URL'] || begin
      puts "⚠️  Veuillez fournir l'URL à scraper"
      puts "Usage: rake scraper:avocats URL='https://exemple.com'"
      exit
    end

    output_file = ENV['OUTPUT'] || 'avocats.csv'

    puts "=" * 60
    puts "🚀 SCRAPING D'AVOCATS"
    puts "=" * 60
    puts "URL: #{url}"
    puts "Fichier de sortie: #{output_file}"
    puts "=" * 60
    puts ""

    scraper = AvocatScraper.new(url)
    scraper.export_to_csv(output_file)

    puts ""
    puts "=" * 60
    puts "✨ Terminé ! Fichier disponible: #{output_file}"
    puts "=" * 60
  end

  desc "Inspecter la structure HTML d'une page"
  task :inspect do
    url = ENV['URL'] || begin
      puts "⚠️  Veuillez fournir l'URL à inspecter"
      puts "Usage: rake scraper:inspect URL='https://exemple.com'"
      exit
    end

    require 'nokogiri'
    require 'open-uri'

    puts "🔍 Inspection de: #{url}"
    puts ""

    html = URI.open(url)
    doc = Nokogiri::HTML(html)

    puts "📋 Classes CSS les plus fréquentes:"
    classes = doc.css('[class]').map { |e| e['class'] }.flat_map { |c| c.split }
    classes.tally.sort_by { |_, count| -count }.first(20).each do |klass, count|
      puts "  - .#{klass} (#{count}x)"
    end

    puts ""
    puts "🏷️  IDs trouvés:"
    doc.css('[id]').first(10).each do |element|
      puts "  - ##{element['id']}"
    end
  end
end
