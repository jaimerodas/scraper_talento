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
    return unless candidate_url.match?(URI.regexp)

    @browser.visit candidate_url

    begin
      gather_candidate_data
    rescue Capybara::ElementNotFound
      reset_session
      explore_candidate(candidate_url)
    end
  end

  def gather_candidate_data
    if old_candidate? then @old += 1
    elsif not_confidential? then show_candidate_details
    else
      @confidential += 1
      return
    end
    save_candidate_data
  end

  def save_candidate_data
    CSV.open('resultados.csv', 'a') do |csv|
      csv << [
        name, email, phones, birthday,
        minimum_salary, desired_salary, academic_level
      ]
    end
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

  def old_candidate?
    @browser.find(NAME_SELECTOR).text.match?(CV_REGEX)
  end

  def not_confidential?
    !@browser.all('#datosPersonales .rowDataHeader:nth-child(2) a').empty?
  end

  def prop(selector)
    @browser.all(selector)&.first&.text
  end

  def money(selector)
    prop(selector).gsub(/[\s\$\,]/, '').to_f
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

  def birthday
    prop '#datosPersonales .topContentLeftFieldPersonal'
  end

  def minimum_salary
    money '#cv_empleosolicitado .contentSueldoTop'
  end

  def desired_salary
    money '#cv_empleosolicitado .contentSueldo'
  end

  def academic_level
    prop '#cv_preparacionacademica_group .cv_academica .contentTituloSeccion'
  end
end
