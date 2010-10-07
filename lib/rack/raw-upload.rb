require 'json'
require 'rack/utils'

class Rack::RawUpload
  def initialize(app)
    @app = app
  end

  def call(env)
    Instance.new(@app, env).run
  end

  class Instance 
    def initialize(app, env)
      @app, @env = app, env
    end

    def run
      convert! if @env['HTTP_X_RAW_UPLOAD'] == 'true'
      @app.call(@env)
    end

    def convert!
      @env['rack.request.form_hash'] = form_hash

      # Signal to Rack that the input has already been parsed.
      @env['rack.request.form_input'] = @env['rack.input']
    end
    
    def form_hash
      result = other_params

      # Handle stuff like the field name being foo[bar][baz].
      Rack::Utils.normalize_params(result, field_name, file_hash)

      result
    end

    def other_params
      if other_params_json
        result = JSON.parse(other_params_json)
        if result.is_a? Hash
          result
        else
          raise "Value of X-Raw-Upload-Other-Params-JSON must be a hash."
        end
      else
        {}
      end
    end

    def other_params_json
      @env['HTTP_X_RAW_UPLOAD_OTHER_PARAMS_JSON']
    end

    def file_hash
      {
        :filename => file_name,
        :name => field_name,
        :type => @env['CONTENT_TYPE'],
        :tempfile => tempfile
      }
    end

    def file_name
      @env['HTTP_X_RAW_UPLOAD_FILE_NAME']
    end

    def field_name
      @env['HTTP_X_RAW_UPLOAD_FIELD_NAME']
    end

    def tempfile
      result = Tempfile.new('raw-upload.')

      # Fixes encoding problem with Ruby 1.9.
      result = open(result.path, "r+:BINARY")

      result << input
      result.flush
      result.rewind
      result
    end

    def input
      @env['rack.input'].read
    ensure
      @env['rack.input'].rewind
    end
  end
end
