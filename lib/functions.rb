module HelperFunctions
  # This method blocks anything executed within it from printing to STDOUT
  def capture_stdout
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    fake.string
  end

  # This method filters out the occ results
  def apply_filter(filter)
    script = "ClickCheckBox('#{filter}')"

    capture_stdout do
      @browser.execute_script(script)
    end

    sleep 10
  end

  def print_number_of_candidates
    results = @browser.find('.ts_facets_numcand_desc .ts_facets_numcand').text
    puts "Hay #{results} resultados"
  end
end
