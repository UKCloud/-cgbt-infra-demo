require 'serverspec'
require 'net/ssh'
require 'net/ssh/proxy/command'
require 'json'

terraform = JSON.parse(`terraform output -json`)
jumpbox_host = terraform["jumpbox_address"]["value"]
jumpbox_user = terraform["jumpbox_user"]["value"]
private_key  = terraform["private_key"]["value"]

proxy = Net::SSH::Proxy::Command.new("ssh -i #{private_key} #{jumpbox_user}@#{jumpbox_host} nc %h %p")

set :backend, :ssh

if ENV['ASK_SUDO_PASSWORD']
  begin
    require 'highline/import'
  rescue LoadError
    fail "highline is not available. Try installing it."
  end
  set :sudo_password, ask("Enter sudo password: ") { |q| q.echo = false }
else
  set :sudo_password, ENV['SUDO_PASSWORD']
end

host = ENV['TARGET_HOST']

options = Net::SSH::Config.for(host)

options[:user] ||= Etc.getlogin
options[:proxy] = proxy
#options[:verbose] = :debug
options[:keys] = private_key

set :host,        options[:host_name] || host
set :ssh_options, options

set :request_pty, true

# Disable sudo
#set :disable_sudo, true


# Set environment variables
# set :env, :LANG => 'C', :LC_MESSAGES => 'C'

# Set PATH
# set :path, '/sbin:/usr/local/sbin:$PATH'
