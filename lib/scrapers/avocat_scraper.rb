require 'nokogiri'
require 'open-uri'
require 'csv'

class AvocatScraper
  def initialize(url)
    @url = url
  end

  def scrape
    puts "🔍 Connexion à #{@url}..."

    html = URI.open(@url)
    doc = Nokogiri::HTML(html)

    avocats = []

    puts "📊 Analyse de la page..."

    doc.css('.lawyerprofilebox').each_with_index do |avocat, index|
      puts "  Traitement avocat #{index + 1}..."
      data = extract_avocat_data(avocat)
      avocats << data
    end

    puts "✅ #{avocats.count} avocats trouvés"
    avocats
  end

  def export_to_csv(filename = 'avocats.csv')
    avocats = scrape

    CSV.open(filename, 'w', headers: true) do |csv|
      # En-têtes
      csv << [
        'post_title',
        'post_content',
        'post_status',
        'post_type',
        'adresse',
        'ville',
        'code_postal',
        'specialites',
        'langues',
        'consultation_video',
        'telephone',
        'email',
        'profil_url',
        'photo_url'
      ]

      # Données
      avocats.each do |avocat|
        csv << [
          avocat[:nom],
          avocat[:description],
          'publish',
          'avocat',
          avocat[:adresse],
          avocat[:ville],
          avocat[:code_postal],
          avocat[:specialites],
          avocat[:langues],
          avocat[:consultation_video],
          avocat[:telephone],
          avocat[:email],
          avocat[:profil_url],
          avocat[:photo_url]
        ]
      end
    end

    puts "✅ Export terminé : #{avocats.count} avocats dans #{filename}"
  end

  private

  def extract_avocat_data(avocat)
    # 1. EXTRAIRE LE NOM
    nom_element = avocat.css('.name').first
    nom_complet = nom_element ? nom_element.text.strip : ''

    # 2. EXTRAIRE L'ADRESSE COMPLÈTE
    adresse_element = avocat.css('.address').first
    adresse_complete = adresse_element ? adresse_element.text.strip : ''

    # 3. EXTRAIRE CODE POSTAL ET VILLE
    code_postal = ''
    ville = ''
    adresse_rue = ''

    if adresse_complete.match(/(\d{5})\s+([A-Z\s]+)/)
      code_postal = $1
      ville = $2.strip
      adresse_rue = adresse_complete.gsub(/#{code_postal}\s+#{ville}/, '').strip
    end

    # 4. EXTRAIRE LES SPÉCIALITÉS
    specialites_elements = avocat.css('.competences .compname')
    specialites = specialites_elements.map { |s| s.text.strip }.join(', ')

    # 5. VÉRIFIER CONSULTATION VIDÉO
    consultation_video = avocat.text.include?('Accepte les consultations vidéo') ? 'Oui' : 'Non'

    # 6. EXTRAIRE LES LANGUES
    langues = []
    avocat.css('.lang .flag').each do |flag|
      alt = flag['alt'] || ''
      title = flag['title'] || ''
      texte = "#{alt} #{title}".downcase

      langues << 'FR' if texte.include?('français') || texte.include?('french')
      langues << 'EN' if texte.include?('anglais') || texte.include?('english')
      langues << 'ES' if texte.include?('espagnol') || texte.include?('spanish')
      langues << 'DE' if texte.include?('allemand') || texte.include?('german')
      langues << 'IT' if texte.include?('italien') || texte.include?('italian')
    end

    # 7. EXTRAIRE L'URL DU PROFIL
    profil_link = avocat.css('.link-profil').first
    profil_url = ''

    if profil_link
      href = profil_link['href']
      if href
        profil_url = href.start_with?('http') ? href : "https://consultation.avocat.fr#{href}"
      end
    end

    # 8. EXTRAIRE L'URL DE LA PHOTO
    photo_element = avocat.css('.profilphoto img').first
    photo_url = ''

    if photo_element
      src = photo_element['src']
      if src
        photo_url = src.start_with?('http') ? src : "https://consultation.avocat.fr#{src}"
      end
    end

    # 9. RETOURNER LES DONNÉES
    {
      nom: nom_complet,
      adresse: adresse_rue,
      ville: ville,
      code_postal: code_postal,
      specialites: specialites,
      langues: langues.uniq.join(', '),
      consultation_video: consultation_video,
      telephone: '',
      email: '',
      description: specialites,
      profil_url: profil_url,
      photo_url: photo_url
    }
  end
end
