# frozen_string_literal: true

# This module holds all of the methods necessary to process candidates.
module CandidateProcessor
  CV_REGEX = /\s\(No\.\sCV:\s\d+\)$/
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
    if new_candidate? then show_candidate_details
    else @old += 1
    end
    @candidates << [name, email, phones]
  end

  def reset_session
    @resets += 1
    @browser = Capybara::Session.new(:poltergeist)
    login
  end

  def show_candidate_details
    @browser.find('#datosPersonales .rowDataHeader:nth-child(2) a').click
    sleep 5
    @new += 1
  end

  def new_candidate?
    !@browser.find(NAME_SELECTOR).text.match?(CV_REGEX)
  end

  def prop(selector)
    @browser.all(selector)&.first&.text
  end

  def name
    @browser.find(NAME_SELECTOR).text.sub(CV_REGEX, '').strip
  end

  def email
    prop '#OCD_contactInfo .rowData a'
  end

  def phones
    @browser.all('#OCD_contactInfo .contentRightFieldPersonal')
            .map { |e| e.text.gsub(/[\s\(\)\+]/, '') }
            &.select { |e| e =~ /^\d+$/ }
            &.uniq
            &.join(', ')
  end
end
