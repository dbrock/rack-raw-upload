require 'rack/raw-upload'
require 'rack/test'
require 'json'

describe Rack::RawUpload do
  include Rack::Test::Methods

  it "should convert raw upload into simulated form upload" do
    upload!
    upload_should_have_been_converted
  end

  it "should not kick in when X-Raw-Upload is not set" do
    upload! 'HTTP_X_RAW_UPLOAD' => nil
    upload_should_not_have_been_converted
  end

  it "should not kick in when X-Raw-Upload is set to 'false'" do
    upload! 'HTTP_X_RAW_UPLOAD' => 'false'
    upload_should_not_have_been_converted
  end

  it "should pass along additional parameters" do
    json = JSON.generate(:foo => [1, 2, 3], :bar => '1 2 3')
    upload! 'HTTP_X_RAW_UPLOAD_OTHER_PARAMS_JSON' => json
    upload_should_have_been_converted
    last_request.POST['foo'].should == [1, 2, 3]
    last_request.POST['bar'].should == "1 2 3"
  end

  it "should understand nested field names" do
    upload! 'HTTP_X_RAW_UPLOAD_FIELD_NAME' => 'foo[bar][baz]'
    upload_should_have_been_converted \
      :actual_file => last_request.POST['foo']['bar']['baz']
  end

  EXAMPLE_CONTENT_TYPE = 'application/example'
  EXAMPLE_FIELD_NAME = 'example-field-name'
  EXAMPLE_FILE_NAME = __FILE__

  def upload!(env = {})
    post('/', {}, default_env.merge(env))
  end

  def default_env
    {
      'CONTENT_TYPE' => EXAMPLE_CONTENT_TYPE,
      'HTTP_X_RAW_UPLOAD' => 'true',
      'HTTP_X_RAW_UPLOAD_FIELD_NAME' => EXAMPLE_FIELD_NAME,
      'HTTP_X_RAW_UPLOAD_FILE_NAME' => EXAMPLE_FILE_NAME,
      'rack.input' => File.open(EXAMPLE_FILE_NAME)
    }
  end
  
  def upload_should_have_been_converted(options = {})
    actual_file = options[:actual_file] ||
      last_request.POST[EXAMPLE_FIELD_NAME]

    last_response.should be_ok
    actual_file.should be_a(Hash)
    
    expected_content = File.read(EXAMPLE_FILE_NAME)
    actual_content = actual_file[:tempfile].read
      
    actual_content.should == expected_content
    actual_file[:type].should == EXAMPLE_CONTENT_TYPE
    actual_file[:filename].should == EXAMPLE_FILE_NAME
  end

  def upload_should_not_have_been_converted
    last_response.should be_ok
    last_request.POST.should_not have_key(EXAMPLE_FIELD_NAME)
  end

  def app
    Rack::Builder.new do
      use Rack::RawUpload
      run lambda { [200, { 'Content-Type' => 'text/plain' }, ''] }
    end
  end
end
