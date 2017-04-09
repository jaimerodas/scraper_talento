# frozen_string_literal: true

# This module holds all of the methods necessary to process candidates.
module CandidateProcessor
  CANDIDATE_MATCHER = /\s\(No\.\sCV:\s\d+\)$/
  NAME_SELECTOR = '#datosPersonales .rowDataHeader:nth-child(2)'

  private

  def gather_candidate_urls
    capture_stdout do
      @browser.all('table.resumes .ts_cv_id').each do |c|
        @candidate_urls << c[:href].gsub(/\?.+$/, '')
      end
    end
  end

  def explore_candidate(candidate_url)
    @browser.visit candidate_url

    begin
      gather_candidate_data
    rescue Capybara::ElementNotFound
      reset_session
      explore_candidate(candidate_url)
    end
  end

  def gather_candidate_data
    if old_candidate?
      @candidates << [name, email, phones]
      @old += 1
    else
      @new += 1
    end
  end

  def reset_session
    @resets += 1
    @browser = Capybara::Session.new(:poltergeist)
    login
  end

  def old_candidate?
    @browser.find(NAME_SELECTOR).text.match?(CANDIDATE_MATCHER)
  end

  def name
    @browser.find(NAME_SELECTOR).text.sub(CANDIDATE_MATCHER, '').strip
  end

  def email
    @browser.all('#OCD_contactInfo .rowData a').first.text
  end

  def phones
    @browser.all(
      '#OCD_contactInfo .contentRightFieldPersonal'
    ).map { |e| e.text.strip }&.select { |e| e =~ /^[\d\s\(\)\+]+$/ }&.join(
      ', '
    )
  end
end
