require 'json'
require 'rack/utils'

class RackRawUpload
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['HTTP_X_RAW_UPLOAD'] == 'true'
      Instance.new(@app, env).run
    else
      @app.call(env)
    end
  end

  class Instance 
    def initialize(app, env)
      @app, @env = app, env
    end

    def run
      @env['rack.request.form_input'] = input
      @env['rack.request.form_hash'] = form_hash

      @app.call(@env)
    end
    
    def input
      @env['rack.input']
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
      result = open(result.path, "r+:BINARY")
      result << input.read
      result.flush
      result.rewind
      result
    end
  end
end
