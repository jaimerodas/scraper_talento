# frozen_string_literal: true

module ScraperTalento
  # The main class. It goes to OCC, logs in, searches for candidates, obtains
  # info from each of the results, and stores them in a CSV file.
  class Runner
    include HelperFunctions
    include ResumeGatherer
    include CandidateProcessor

    # Results
    RESULTS_COLUMNS = [
      'Nombre',
      'Email',
      'Teléfonos',
      'Fecha de Nacimiento',
      'Sueldo Mínimo',
      'Sueldo Deseado',
      'Nivel Académico'
    ].freeze

    # URLs
    BASE_URL = 'https://recluta11.occ.com.mx'
    LOGIN_PAGE = "#{BASE_URL}/Autenticacion/LogOn"
    SEARCH_PAGE = "#{BASE_URL}/Candidatos/BuscarB"

    def initialize
      Capybara.register_driver :poltergeist do |app|
        Capybara::Poltergeist::Driver.new(app, js_errors: false)
      end
      @config = YAML.load_file(File.dirname(__FILE__) + '/../../config.yml')
      @browser = Capybara::Session.new(:poltergeist)
      @candidate_urls = @candidates = []
      @old = @new = @confidential = @resets = @tries = 0
    end

    def run
      puts 'Hacemos Login'
      login
      start_search
      filter_results
      init_files
      scrape_urls
      scrape_resumes
    end

    private

    def login
      capture_stdout do
        @browser.visit LOGIN_PAGE
        @browser.fill_in 'username', with: @config['login']['username']
        @browser.fill_in 'password', with: @config['login']['password']
        @browser.find_button('btn_submit').click
      end
    end

    def start_search
      puts 'Iniciando busqueda'
      capture_stdout do
        @browser.visit SEARCH_PAGE
        @browser.fill_in 'SearchValue', with: @config['search']['string']
        @browser.find_button('Talent search').click

        sleep 5
      end
    end

    def filter_results
      (['LOC-1'] + @config['search']['filters']).each do |filter|
        apply_filter(filter)
      end

      puts 'Aumentando resultados a 1000 por hoja'
      @browser.execute_script('ResultsByPage(1000)')
      sleep 10
    end

    def scrape_resumes
      save_urls_to_file

      puts "Recolecté #{@candidate_urls.count} candidatos"
      bar = ProgressBar.new(@candidate_urls.size)
      bar.write

      @candidate_urls.each do |c|
        explore_candidate(c)
        bar.increment!
      end

      print_search_results
    end

      puts 'Empezamos archivo'

    end
  end
end
