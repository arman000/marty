#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end
begin
  require 'rdoc/task'
rescue LoadError
  require 'rdoc/rdoc'
  require 'rake/rdoctask'
  RDoc::Task = Rake::RDocTask
end

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Marty'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

APP_RAKEFILE = File.expand_path('../spec/dummy/Rakefile', __FILE__)
load 'rails/tasks/engine.rake'

Bundler::GemHelper.install_tasks

task default: 'app:spec'

namespace :marty do
  desc 'Merge the results of various SimpleCov coverage reports'
  task merge_coverage_reports: :environment do
    require_relative 'spec/support/simplecov_helper'
    SimpleCovHelper.configure_profile
    puts 'Merging code coverage reports...'
    SimpleCovHelper.merge_all_results!
  end
end
