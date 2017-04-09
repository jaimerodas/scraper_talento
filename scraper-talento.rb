require 'capybara/poltergeist'
require 'progress_bar'
require 'csv'

require_relative 'lib/functions.rb'
require_relative 'lib/candidate.rb'

class ScraperTalento
  include HelperFunctions
  include CandidateProcessor

  # Parámetros de búsqueda
  SEARCH_STRING = 'Asesor Comercial'.freeze
  SEARCH_FILTERS = %w(AGE-2 AGE-3 AL-5 AL-6 AL-7 SAL-1 SAL-2).freeze

  # Datos registro
  OCC_USERNAME = ENV['OCC_USERNAME']
  OCC_PASSWORD = ENV['OCC_PASSWORD']

  # Direcciones de internet
  BASE_URL = 'https://recluta11.occ.com.mx'.freeze
  LOGIN_PAGE = "#{BASE_URL}/Autenticacion/LogOn".freeze
  SEARCH_PAGE = "#{BASE_URL}/Candidatos/BuscarB".freeze

  # Otros
  CANDIDATE_MATCHER = /\(No\.\sCV:\s\d+\)$/

  def initialize
    config_capybara
    @browser = Capybara::Session.new(:poltergeist)
    @candidate_urls = []
    @candidates = []
  end

  def run
    puts 'Hacemos Login'
    login
    start_search
    filter_results
    gather_candidates_info
    save_info
  end

  private

  def config_capybara
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, js_errors: false)
    end
  end

  # Entra a la pag y hace login
  def login
    capture_stdout do
      @browser.visit LOGIN_PAGE
      @browser.fill_in 'username', with: OCC_USERNAME
      @browser.fill_in 'password', with: OCC_PASSWORD
      @browser.find_button('btn_submit').click
    end
  end

  # Inicia la busqueda
  def start_search
    puts 'Iniciando busqueda'
    capture_stdout do
      @browser.visit SEARCH_PAGE
      @browser.fill_in 'SearchValue', with: SEARCH_STRING
      @browser.select 'México-DF Y Zona Metro.', from: 'Location'
      @browser.find_button('Talent search').click

      sleep 5
      print_number_of_candidates
    end
  end

  # Filtra los resultados
  def filter_results
    puts 'Filtrando Resultados'
    bar = ProgressBar.new(SEARCH_FILTERS.size)

    SEARCH_FILTERS.each do |filter|
      apply_filter(filter)
      bar.increment!
    end

    @browser.execute_script('ResultsByPage(1000)')
    sleep 10
  end

  # Junta los urls de los candidatos
  def gather_candidates_info
    capture_stdout do
      @browser.all('table.resumes .ts_cv_id').each do |c|
        @candidate_urls << c[:href].gsub(/\?.+$/, '')
      end
    end

    puts "Recolecté #{@candidate_urls.count} candidatos"

    bar = ProgressBar.new(@candidate_urls.size)
    @candidate_urls.each { |c| explore_candidate(c); bar.increment! }
  end

  def save_info
    puts 'Guardamos información'

    CSV.open('resultados.csv', 'w') do |csv|
      csv << %W(Nombre Email Tel\u00E9fonos)
      @candidates.each { |c| csv << c }
    end
  end
end

ScraperTalento.new.run
