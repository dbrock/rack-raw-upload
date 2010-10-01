require 'rubygems'
require 'rack/test'
require 'shoulda'
require 'rack/raw-upload'
require 'json'

class RawUploadTest < Test::Unit::TestCase
  include Rack::Test::Methods

  EXAMPLE_CONTENT_TYPE = 'application/example'
  EXAMPLE_FIELD_NAME = 'example-field-name'
  EXAMPLE_FILE_NAME = __FILE__

  def app
    Rack::Builder.new do
      use Rack::RawUpload
      run Proc.new { [200, { 'Content-Type' => 'text/plain' }, ''] }
    end
  end

  def upload!(env = {})
    env = {
      'REQUEST_METHOD' => 'POST',
      'CONTENT_TYPE' => EXAMPLE_CONTENT_TYPE,
      'HTTP_X_RAW_UPLOAD' => 'true',
      'HTTP_X_RAW_UPLOAD_FIELD_NAME' => EXAMPLE_FIELD_NAME,
      'HTTP_X_RAW_UPLOAD_FILE_NAME' => EXAMPLE_FILE_NAME,
      'PATH_INFO' => '/',
      'rack.input' => File.open(EXAMPLE_FILE_NAME),
    }.merge(env)

    request(env['PATH_INFO'], env)
  end

  def actual_fields
    last_request.POST
  end

  def actual_file
    @actual_file || actual_fields[EXAMPLE_FIELD_NAME]
  end

  context "raw file upload" do
    should "kick in when X-Raw-Upload is set to 'true'" do
      upload!
      assert actual_file
    end

    should "not kick in when X-Raw-Upload is not set" do
      upload! 'HTTP_X_RAW_UPLOAD' => nil
      assert_successful_non_upload
    end

    should "not kick in when X-Raw-Upload is set to 'false'" do
      upload! 'HTTP_X_RAW_UPLOAD' => 'false'
      assert_successful_non_upload
    end

    should "convert into simulated form upload" do
      upload!
      assert_successful_upload
    end

    should "pass along additional parameters" do
      json = JSON.generate :foo => [1, 2, 3], :bar => '1 2 3'
      upload! 'HTTP_X_RAW_UPLOAD_OTHER_PARAMS_JSON' => json
      assert_equal [1, 2, 3], actual_fields['foo']
      assert_equal "1 2 3", actual_fields['bar']
      assert_successful_upload
    end

    should "understand nested field names" do
      upload! 'HTTP_X_RAW_UPLOAD_FIELD_NAME' => 'foo[bar][baz]'
      @actual_file = actual_fields['foo']['bar']['baz']
      assert_successful_upload
    end
  end
  
  def assert_successful_upload
    assert last_response.ok?
    assert actual_file.is_a? Hash
    
    expected_content = File.read(EXAMPLE_FILE_NAME)
    actual_content = actual_file[:tempfile].read
      
    assert_equal expected_content, actual_content
    assert_equal EXAMPLE_CONTENT_TYPE, actual_file[:type]
    assert_equal EXAMPLE_FILE_NAME, actual_file[:filename]
  end

  def assert_successful_non_upload
    assert last_response.ok?
    assert !last_request.POST.has_key?(EXAMPLE_FIELD_NAME)
  end
end
