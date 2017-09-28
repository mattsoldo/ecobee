module Ecobee
class HTTPError < StandardError ; end
  class AuthError < HTTPError ; end

  class HTTP

    def initialize(log_file: nil, token: nil)
      raise ArgumentError, 'Missing token' unless token
      @token = token
      open_log log_file
      http
    end

    def get(
      arg: nil,
      no_auth: false,
      resource_prefix: '1/',
      retries: 3,
      options: nil,
      validate_status: true
    )
      uri = URI.escape(sprintf("#{Ecobee::API_URI_BASE}/%s%s%s",
                               resource_prefix,
                               arg.to_s.sub(/^\//, ''),
                               options ? "?json=#{options.to_json}" : ''))
      log "http.get uri=#{uri}"
      request = Net::HTTP::Get.new(URI(uri))
      request['Content-Type'] = *CONTENT_TYPE
      request['Authorization'] = @token.authorization unless no_auth
      response = nil
      retries.times do
        http_response = http.request request
        response = JSON.parse(http_response.body)
        log "http.get response=#{response.pretty_inspect}"
        response = validate_status(response) if validate_status
        break unless response == :retry
        sleep 3
      end
      case response
      when :retry
        raise Ecobee::HTTPError, {
          message: 'HTTP.get: retries exhausted',
          status: nil
        }.to_json
      else
        response
      end
    rescue SocketError => msg
      raise Ecobee::HTTPError, {
        message: "HTTP.get SocketError => #{msg}",
        status: nil
      }.to_json
    rescue JSON::ParserError => msg
      raise Ecobee::HTTPError, {
        message: "HTTP.get JSON::ParserError => #{msg}",
        status: nil
      }.to_json
    end

    def log(arg)
      return unless @log_fh
      if arg.length > MAX_LOG_LENGTH
        arg = arg.slice(0, MAX_LOG_LENGTH).chomp + "\n ...truncated..."
      end
      @log_fh.puts "#{Time.now} #{arg.chomp}"
      @log_fh.flush
    end

    def post(
      arg: nil,
      body: nil,
      no_auth: false,
      resource_prefix: '1/',
      retries: 3,
      options: {},
      validate_status: true
    )
      uri = URI.escape(sprintf("#{Ecobee::API_URI_BASE}/%s%s%s",
                               resource_prefix,
                               arg.to_s.sub(/^\//, ''),
                               options.length > 0 ? "?json=#{options.to_json}" : ''))
      log "http.post uri=#{uri}"
      request = Net::HTTP::Post.new(URI(uri))
      request['Content-Type'] = *CONTENT_TYPE
      request['Authorization'] = @token.authorization unless no_auth
      if body
        log "http.post body=#{body.pretty_inspect}"
        request.body = JSON.generate(body)
      elsif options.length > 0
        request.set_form_data({ 'format' => 'json' }.merge(options))
      end
      response = nil
      retries.times do
        http_response = http.request request
        response = JSON.parse(http_response.body)
        log "http.post response=#{response.pretty_inspect}"
        response = validate_status(response) if validate_status
        break unless response == :retry
        sleep 3
      end
      case response
      when :retry
        raise Ecobee::HTTPError, {
          message: 'HTTP.post: retries exhausted',
          status: nil
        }.to_json
      else
        response
      end
    rescue SocketError => msg
      raise Ecobee::HTTPError, {
        message: "HTTP.post SocketError => #{msg}",
        status: nil
      }.to_json
    rescue JSON::ParserError => msg
      raise Ecobee::HTTPError, {
        message: "HTTP.post JSON::ParserError => #{msg}",
        status: nil
      }.to_json
    end

    private

    def http
      @http ||= Net::HTTP.new(API_HOST, API_PORT)
      unless @http.active?
        @http.use_ssl = true
        Net::HTTP.start(API_HOST, API_PORT)
      end
      @http
    rescue SocketError => msg
      raise Ecobee::HTTPError, {
        message: "HTTP.http SocketError => #{msg}",
        status: nil
      }.to_json
    end

    def open_log(log_file)
      return unless log_file
      log_file = File.expand_path log_file
      @log_fh = File.new(log_file, 'a')
    rescue Exception => msg
      raise Ecobee::HTTPError, {
        message: "open_log: #{msg}",
        status: nil
      }.to_json
    end

    def validate_status(response)
      if !response.key? 'status'
        raise Ecobee::HTTPError, {
          message: 'Validate Error: Missing Status',
          status: nil
        }.to_json
      elsif !response['status'].key? 'code'
        raise Ecobee::HTTPError, {
          message: 'Validate Error: Missing Status Code',
          status: nil
        }.to_json
      elsif response['status']['code'] == 14
        log "validate_status: token expired access_token_expire: #{@token.access_token_expire}"
        log "validate_status:                               now: #{Time.now.to_i}"
        :retry
      elsif response['status']['code'] != 0
        raise Ecobee::HTTPError, {
          message: "Validate Error: (Code #{response['status']['code']}) " + "#{response['status']['message']}",
          status: response['status']['code']
        }.to_json
      else
        response
      end
    end

  end

end
