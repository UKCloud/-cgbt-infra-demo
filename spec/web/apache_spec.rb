require 'spec_helper'

describe package('httpd') do
  it { should be_installed }
end

describe service('httpd') do
  it { should be_enabled }
  it { should be_running }
end

describe port(80) do
  it { should be_listening }
end

describe 'should respond to an HTTP request' do
  describe command('curl -k --stderr - http://localhost/index.php') do
    its(:stdout) { should match /.*<h2>CGBT .* Demo WebApp<\/h2>.*/ }
  end
end