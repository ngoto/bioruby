#
# = Rakefile - helper of developement and packaging
#
# Copyright::   Copyright (C) 2009 Naohisa Goto <ng@bioruby.org>
# License::     The Ruby License
#

require 'rubygems'
require 'erb'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/rdoctask'

load "./lib/bio/version.rb"
BIO_VERSION_RB_LOADED = true

# Version string for tar.gz, tar.bz2, or zip archive.
# If nil, use the value in lib/bio.rb
# Note that gem version is always determined from bioruby.gemspec.erb.
version = ENV['BIORUBY_VERSION'] || Bio::BIORUBY_VERSION.join(".")
version = nil if version.to_s.empty?
extraversion = ENV['BIORUBY_EXTRA_VERSION'] || Bio::BIORUBY_EXTRA_VERSION
extraversion = nil if extraversion.to_s.empty?
BIORUBY_VERSION = version
BIORUBY_EXTRA_VERSION = extraversion

task :default => "test"

Rake::TestTask.new do |t|
  t.test_files = FileList["test/{unit,functional}/**/test_*.rb"]
end

# files not included in gem but included in tar archive
tar_additional_files = []

GEM_SPEC_FILE = "bioruby.gemspec"
GEM_SPEC_TEMPLATE_FILE = "bioruby.gemspec.erb"

# gets gem spec string
gem_spec_string = ERB.new(File.read(GEM_SPEC_TEMPLATE_FILE)).result

# gets gem spec object
spec = eval(gem_spec_string)

# adds notice of automatically generated file
gem_spec_string = "# This file is automatically generated from #{GEM_SPEC_TEMPLATE_FILE} and\n# should NOT be edited by hand.\n# \n" + gem_spec_string

# compares current gemspec file and newly generated gemspec string
current_string = File.read(GEM_SPEC_FILE) rescue nil
if current_string and current_string != gem_spec_string then
  #Rake::Task[GEM_SPEC_FILE].invoke
  flag_update_gemspec = true
else
  flag_update_gemspec = false
end

desc "Update gem spec file"
task :gemspec => GEM_SPEC_FILE

desc "Force update gem spec file"
task :regemspec do
  #rm GEM_SPEC_FILE, :force => true
  Rake::Task[GEM_SPEC_FILE].execute
end

desc "Update #{GEM_SPEC_FILE}"
file GEM_SPEC_FILE => [ GEM_SPEC_TEMPLATE_FILE, 'Rakefile',
                        'lib/bio/version.rb' ] do |t|
  puts "creates #{GEM_SPEC_FILE}"
  File.open(t.name, 'w') do |w|
    w.print gem_spec_string
  end
end

task :package => [ GEM_SPEC_FILE ] do
  Rake::Task[:regemspec].invoke if flag_update_gemspec
end

Rake::PackageTask.new("bioruby") do |pkg|
  #pkg.package_dir = "./pkg"
  pkg.need_tar_gz = true
  pkg.package_files.import(spec.files)
  pkg.package_files.include(*tar_additional_files)
  pkg.version = (BIORUBY_VERSION || spec.version) + BIORUBY_EXTRA_VERSION.to_s
end

Rake::GemPackageTask.new(spec) do |pkg|
  #pkg.package_dir = "./pkg"
end

Rake::RDocTask.new do |r|
  r.rdoc_dir = "rdoc"
  r.rdoc_files.include(*spec.extra_rdoc_files)
  r.rdoc_files.import(spec.files.find_all {|x| /\Alib\/.+\.rb\z/ =~ x})
  #r.rdoc_files.exclude /\.yaml\z"
  opts = spec.rdoc_options.to_a.dup
  if i = opts.index('--main') then
    main = opts[i + 1]
    opts.delete_at(i)
    opts.delete_at(i)
  else
    main = 'README.rdoc'
  end
  r.main = main
  r.options = opts
end
