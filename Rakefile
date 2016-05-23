require 'bundler/gem_tasks'

def specs(dir)
  FileList["spec/#{dir}/*_spec.rb"].shuffle.join(' ')
end

desc 'Runs all the specs'
task :specs do
  sh "bundle exec rspec #{specs('**')}"
end

task :default => :specs

