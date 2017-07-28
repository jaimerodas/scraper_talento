module ScraperTalento
  require 'csv'
  require 'uri'
  require 'yaml'
  require 'json'
  require 'net/http'
  require 'active_support/inflector'

  class Candidate
    def initialize(candidate_array, config)
      first_name, last_name = guess_name(candidate_array[0].titleize)
      @body = {
        first_name: first_name,
        last_name: last_name,
        email: candidate_array[1],
        phone: candidate_array[2],
        source: 'OCC',
        profile_data: [
          { name: 'Cumpleaños', value: candidate_array[3] },
          { name: 'Sueldo Mínimo', value: candidate_array[6] },
          { name: 'Sueldo Deseado', value: candidate_array[7] },
          { name: 'Nivel Académico', value: candidate_array[8] },
          { name: 'Código Postal', value: candidate_array[4] },
          { name: 'Ciudad/Municipio', value: candidate_array[5] },
          { name: 'Fuente', value: candidate_array[10] }
        ],
        opening_id: config['opening_id'],
        stage_id: config['stage_id']
      }
    end

    def self.all
      candidates = []
      config = YAML.load_file(
        File.dirname(__FILE__) + '/../../config.yml'
      )['recruiterbox']

      CSV.foreach('resultados.csv') do |row|
        next if row[0] == 'Show Identity'
        next if not_in_valid_cps(row[4], config['cps'])
        candidates << new(row, config)
      end

      candidates
    end

    def self.post_all
      all.each(&:post)
    end

    def self.not_in_valid_cps(cp, cps)
      return false if cps&.size&.positive?
      return false if cps.include? cp.to_i
      puts "No está en la lista de cps"
      true
    end

    def post
      uri = URI.parse 'https://api.recruiterbox.com/v2/candidates'
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new uri.request_uri,
                                    'Content-Type' => 'application/json'
      request.body = @body.to_json
      request.basic_auth '7767f2fbc7bb46d2968be80f34ef8860', ''

      puts "#{@body[:first_name]} #{@body[:last_name]}"
      http.request(request)
    end

    private

    def guess_name(full_name)
      name_array = full_name.split(' ')

      case name_array.length
      when 2
        first_name = name_array[0]
        last_name = name_array[0]
      when 1
        first_name = name_array[0]
        last_name = ''
      else
        last_name = name_array.pop(2).join(' ')
        first_name = name_array.join(' ')
      end

      [first_name, last_name]
    end
  end
end
