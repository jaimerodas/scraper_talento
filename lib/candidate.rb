module CandidateProcessor
  CANDIDATE_MATCHER = /\(No\.\sCV:\s\d+\)$/

  private

  def get_candidate_info
    name = @browser.find(
      '#datosPersonales .rowDataHeader:nth-child(2)'
    ).text.gsub(CANDIDATE_MATCHER, '').strip

    email = @browser.all('#OCD_contactInfo .rowData a').first.text

    phones = @browser.all(
      '#OCD_contactInfo .contentRightFieldPersonal'
    ).map {|e| e.text.strip }&.select {|e| e =~ /^[\d\s\(\)\+]+$/ }&.join(
      ', '
    )

    @candidates << [name, email, phones]
  end

  def explore_candidate(candidate_url)
    @browser.visit candidate_url

    begin
      name = @browser.find('#datosPersonales .rowDataHeader:nth-child(2)').text
      if name =~ CANDIDATE_MATCHER
        get_candidate_info
        @old += 1
      else
        @new += 1
      end
    rescue Capybara::ElementNotFound
      @resets += 1
      @browser = Capybara::Session.new(:poltergeist)
      login
      explore_candidate(candidate_url)
    end
  end
end
