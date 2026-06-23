#!/usr/bin/env ruby

# ExportMultipleFormats — render Orders.rdl to PDF, Excel, CSV, and HTML
# using the rdlnative in-process library (no subprocess / .NET runtime required).
#
# Build the native library first:
#   dotnet publish RdlNative/Majorsilence.Reporting.RdlNative.csproj \
#       -p:PublishAot=true -o /tmp/rdlnative-pub
#
# Run:
#   RDLNATIVE_LIB=/tmp/rdlnative-pub/librdlnative.so ruby test4-export-multiple-formats.rb
#
# Output: orders.pdf / orders.xlsx / orders.csv / orders.html in the output directory

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'majorsilence_reporting/report_native'

# SETUP
current_directory = File.dirname(File.expand_path(__FILE__))
base_directory    = File.expand_path(File.join(current_directory, '..', '..', '..'))

db_path     = File.expand_path(File.join(base_directory, 'Examples', 'ExportMultipleFormats', 'sqlitetestdb2.db'))
report_path = File.expand_path(File.join(base_directory, 'Examples', 'ExportMultipleFormats', 'Orders.rdl'))

lib_name =
  if Gem.win_platform?
    'rdlnative.dll'
  elsif RUBY_PLATFORM =~ /darwin/
    'librdlnative.dylib'
  else
    'librdlnative.so'
  end

lib_path = ENV['RDLNATIVE_LIB'] ||
           File.join(base_directory, 'RdlNative', 'bin', 'Release', 'net10.0', lib_name)

output_directory = File.join(current_directory, 'output')
Dir.mkdir(output_directory) unless Dir.exist?(output_directory)

# REPORT EXAMPLE
fns = RdlLibrary.load(lib_path)
rpt = ReportNative.new(fns, report_path)
rpt.set_connection_string('Data Source=' + db_path)

formats = [
  ['orders.pdf',  'pdf'],
  ['orders.xlsx', 'xlsx'],
  ['orders.csv',  'csv'],
  ['orders.html', 'html'],
]

formats.each do |filename, fmt|
  out_path = File.join(output_directory, filename)
  rpt.export(fmt, out_path)
  puts "Written: #{out_path}"
end
