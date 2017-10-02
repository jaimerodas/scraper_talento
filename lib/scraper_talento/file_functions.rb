# frozen_string_literal: true

# These are all the functions we use to manipulate files
module FileFunctions
  # Results
  RESULTS_COLUMNS = [
    'Nombre',
    'Email',
    'Teléfonos',
    'Fecha de Nacimiento',
    'Código Postal',
    'Ciudad/Municipio',
    'Sueldo Mínimo',
    'Sueldo Deseado',
    'Nivel Académico',
    'Estatus',
    'URL'
  ].freeze

  def init_files
    init_urls_file
    init_results_file
  end

  def init_results_file
    print_separator
    puts 'Creamos archivo de Resultados'
    CSV.open("resultados/#{@fname}.csv", 'w') { |csv| csv << RESULTS_COLUMNS }
  end

  def init_urls_file
    print_separator
    puts 'Creamos archivo de URLs'
    File.open("urls/#{@fname}", 'w') {}
  end
end
