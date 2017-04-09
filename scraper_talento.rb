# frozen_string_literal: true
require 'capybara/poltergeist'
require 'progress_bar'
require 'csv'

require_relative 'lib/functions.rb'
require_relative 'lib/candidate.rb'

# The main class. It goes to OCC, logs in, searches for candidates, obtains info
# from each of the results, and stores them in a CSV file.
class ScraperTalento
  include HelperFunctions
  include CandidateProcessor

  # Search Parameters
  SEARCH_STRING = 'Asesor Comercial'
  SEARCH_FILTERS = %w(AGE-2 AGE-3 AL-5 AL-6 AL-7 SAL-1 SAL-2).freeze

  OCC_USERNAME = ENV['OCC_USERNAME']
  OCC_PASSWORD = ENV['OCC_PASSWORD']
  # Login Data

  # URLs
  BASE_URL = 'https://recluta11.occ.com.mx'
  LOGIN_PAGE = "#{BASE_URL}/Autenticacion/LogOn"
  SEARCH_PAGE = "#{BASE_URL}/Candidatos/BuscarB"

  def initialize
    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, js_errors: false)
    end

    @browser = Capybara::Session.new(:poltergeist)
    @candidate_urls = []
    @candidates = []
    @old = 0
    @new = 0
    @resets = 0
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

  def login
    capture_stdout do
      @browser.visit LOGIN_PAGE
      @browser.fill_in 'username', with: OCC_USERNAME
      @browser.fill_in 'password', with: OCC_PASSWORD
      @browser.find_button('btn_submit').click
    end
  end

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

  def gather_candidates_info
    gather_candidate_urls

    puts "Recolecté #{@candidate_urls.count} candidatos"
    bar = ProgressBar.new(@candidate_urls.size)
    @candidate_urls.each do |c|
      explore_candidate(c)
      bar.increment!
    end

    print_search_results
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
