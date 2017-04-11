# frozen_string_literal: true

# This module holds the necessary methods to iterate over the results page
# and gather all of the candidate's urls.
module ResumeGatherer
  def scrape_page_urls
    capture_stdout do
      @browser.all('table.resumes .ts_cv_id').each do |c|
        @candidate_urls << c[:href].gsub(/\?.+$/, '')
      end
    end
  end

  def next_page?
    link = @browser.all('#paginator .ts_li_siguiente a:not(.unavailable)')

    return false if link.empty?

    capture_stdout do
      link.first.click
      sleep 8
    end

    true
  end

  def less_than_limit?
    @candidate_urls.size < @config['search']['limit']
  end

  def save_urls_to_file
    File.open('urls.txt', 'a') do |file|
      @candidate_urls.each { |u| file.puts u }
    end
  end

  def iterate_over_paged_results
    scrape_page_urls
    @candidate_urls = @candidate_urls.uniq
    puts "Llevamos #{@candidate_urls.size} urls"
    iterate_over_paged_results if less_than_limit? && next_page?
  end
end
