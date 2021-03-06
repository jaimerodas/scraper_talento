# frozen_string_literal: true

# This module holds all of the methods necessary to process candidates.
module CandidateProcessor
  CV_REGEX = /\s\(No\.\sCV:\s\d+\)$/
  NAME_SELECTOR = '#datosPersonales .rowDataHeader:nth-child(2)'

  private

  def explore_candidate(candidate_url)
    return unless candidate_url.match?(URI.regexp)
    @browser.visit candidate_url
    @url = candidate_url

    begin
      gather_candidate_data
    rescue Capybara::ElementNotFound
      enough_attempts_left?
      reset_session
      explore_candidate(candidate_url)
    end
  end

  def gather_candidate_data
    if inactive?
      @confidential += 1
      return
    elsif old_candidate?
      @old += 1
      @status = 'repetido'
    elsif confidential?
      @confidential += 1
      return
    else
      @status = 'nuevo'
      show_candidate_details
    end

    save_candidate_data
    @tries = 0
  end

  def enough_attempts_left?
    @tries += 1
    raise 'Ya nos bloquearon la cuenta' if @tries > 2
  end

  def save_candidate_data
    CSV.open("resultados/#{@fname}.csv", 'a') do |csv|
      csv << [
        name, email, phones, birthday, zipcode, city,
        minimum_salary, desired_salary, academic_level, @status, @url
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
    wait_until_ready
    @new += 1
  end

  def wait_until_ready
    tries = 0
    while name == 'Show Identity' && tries < 5
      sleep 5
      tries += 1
    end
    return unless tries == 5

    @browser.find('#datosPersonales .rowDataHeader:nth-child(2) a').click
    sleep 5
  end

  def old_candidate?
    @browser.find(NAME_SELECTOR).text.match?(CV_REGEX)
  end

  def inactive?
    !@browser.all(
      '.ts_mensaje_error_sistema_contenedor_vacante_plantilla'
    ).empty?
  end

  def confidential?
    @browser.all('#datosPersonales .rowDataHeader:nth-child(2) a').empty?
  end

  def prop(selector)
    @browser.all(selector)&.first&.text
  end

  def money(selector)
    prop(selector).gsub(/[\s\$\,]/, '').to_i
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
    prop('#datosPersonales .topContentLeftFieldPersonal')
      .sub(%r[(\d{2})\/(\d{2})\/(\d{4})], '\3-\2-\1')
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

  def zipcode
    @browser.all('#datosPersonales .contentRightFieldPersonal')[1]&.text
  end

  def city
    prop('#datosPersonales .topContentRightFieldPersonal')
  end
end
