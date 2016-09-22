require 'rake'
require 'rspec/core/rake_task'

task :spec    => 'spec:all'
task :default => :spec

hosts = `terraform output server_names`.split('\n').map(&:strip)

namespace :spec do
  task :all => hosts.map {|h| 'spec:' + h.split('.')[0] }

  hosts.each do |host|
    short_name = host.split('.')[0]
    role       = short_name.match(/[^0-9]+/)[0]

    desc "Run serverspec to #{host}"
    RSpec::Core::RakeTask.new(short_name) do |t|
      ENV['TARGET_HOST'] = host
      t.pattern = "spec/{base,#{role}}/*_spec.rb"
    end
  end
end
