# frozen_string_literal: true

# These are all the functions we use to manipulate files
module FileFunctions
  def init_files
    init_urls_file
    init_results_file
  end

  def init_urls_file
    print_separator
    puts 'Creamos archivo de URLs'
    CSV.open('resultados.csv', 'w') { |csv| csv << RESULTS_COLUMNS }
  end

  def init_results_file
    print_separator
    puts 'Creamos archivo de Resultados'
    File.open('urls.txt', 'w') {}
  end
end
