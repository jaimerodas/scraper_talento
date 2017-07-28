# frozen_string_literal: true

module ScraperTalento
  # The main class. It goes to OCC, logs in, searches for candidates, obtains
  # info from each of the results, and stores them in a CSV file.
  class Runner
    include HelperFunctions
    include FileFunctions
    include ResumeGatherer
    include CandidateProcessor

    # URLs
    BASE_URL = 'https://recluta11.occ.com.mx'
    LOGIN_PAGE = "#{BASE_URL}/Autenticacion/LogOn"
    SEARCH_PAGE = "#{BASE_URL}/Candidatos/BuscarB"

    def initialize
      Capybara.register_driver :poltergeist do |app|
        Capybara::Poltergeist::Driver.new(app, js_errors: false, timeout: 500)
      end

      Capybara.default_max_wait_time = 30
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

    def self.post
      ScraperTalento::Candidate.all.post
    end

    def run_full_process
      login
      start_search
      filter_results
      init_files
      scrape_urls
      scrape_resumes
    rescue
      @browser.save_screenshot
    end

    def run_resume_download
      init_results_file
      login
      scrape_resumes
    end

    def import
      gather_results
      process_candidates
      import_into_recruiterbox
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
      puts 'Aumentando resultados a 200 por hoja'
      @browser.execute_script('ResultsByPage(200)')
      sleep 10
    end

    def scrape_urls
      iterate_over_paged_results
      save_urls_to_file
    end

    def scrape_resumes
      urls = File.readlines('urls.txt')
      print_separator
      puts "Voy a sacar info de #{urls.count} CVs"
      bar = ProgressBar.new(urls.size)
      bar.write

      urls.each do |c|
        explore_candidate(c.sub("\n", ''))
        bar.increment!
      end

      print_search_results
    rescue
      print_search_results
    end
  end
end
