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

    def self.full_process
      object = new
      object.run_full_process
      object
    end

    def self.resume_resume_download
      object = new
      object.run_resume_download
      object
    end

    def run_full_process
      login
      start_search
      filter_results
      init_files
      scrape_urls
      scrape_resumes
    end

    def run_resume_download
      init_candidate_urls
      init_results_file
      login
      scrape_resumes
    end

    private

    def login
      puts 'Hacemos Login'
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
      print_separator
      puts 'Aumentando resultados a 1000 por hoja'
      @browser.execute_script('ResultsByPage(1000)')
      sleep 10
    end

    def scrape_urls
      iterate_over_paged_results
      save_urls_to_file
    end

    def scrape_resumes
      puts "Recolecté #{@candidate_urls.count} candidatos"
      bar = ProgressBar.new(@candidate_urls.size)
      bar.write

      @candidate_urls.each do |c|
        explore_candidate(c)
        bar.increment!
      end

      print_search_results
    end

    def init_files
      init_urls_file
      init_results_file
    end

    def init_urls_file
      puts 'Creamos archivo de URLs'
      CSV.open('resultados.csv', 'w') { |csv| csv << RESULTS_COLUMNS }
    end

    def init_results_file
      puts 'Creamos archivo de Resultados'
      File.open('urls.txt', 'w') {}
    end

    def init_candidate_urls
      @candidate_urls = File.open('urls.txt').map
    end
  end
end
