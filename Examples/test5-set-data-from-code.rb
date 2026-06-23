#!/usr/bin/env ruby

# SetDataFromCode — feed data directly into a report with no database at all,
# using the rdlnative in-process library.
#
# Build the native library first:
#   dotnet publish RdlNative/Majorsilence.Reporting.RdlNative.csproj \
#       -p:PublishAot=true -o /tmp/rdlnative-pub
#
# Run:
#   RDLNATIVE_LIB=/tmp/rdlnative-pub/librdlnative.so ruby test5-set-data-from-code.rb
#
# Key patterns shown:
#   - add_data() injects rows from any Ruby data source (array, API response, etc.)
#   - Hash keys must exactly match the <Field Name="..."> values in the RDL
#   - No connection string is needed — SkipDatabaseSchemaValidation is set automatically
#
# Output: sales-report.pdf in the output directory

$LOAD_PATH.unshift File.join(__dir__, '..', 'lib')
require 'majorsilence_reporting/report_native'

# SETUP
current_directory = File.dirname(File.expand_path(__FILE__))
base_directory    = File.expand_path(File.join(current_directory, '..', '..', '..'))

report_path = File.expand_path(File.join(base_directory, 'Examples', 'SetDataFromCode', 'SalesReport.rdl'))

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

# DATA — keys must match <Field Name="..."> in SalesReport.rdl exactly
sales_data = [
  { 'Product' => 'Chai',                   'Region' => 'North America', 'Amount' => '1250.00', 'Quantity' => '50' },
  { 'Product' => 'Chang',                  'Region' => 'North America', 'Amount' =>  '980.50', 'Quantity' => '42' },
  { 'Product' => 'Aniseed Syrup',          'Region' => 'Europe',        'Amount' =>  '432.00', 'Quantity' => '24' },
  { 'Product' => "Chef Anton's Cajun",     'Region' => 'Europe',        'Amount' => '1875.25', 'Quantity' => '75' },
  { 'Product' => "Grandma's Boysenberry",  'Region' => 'Asia Pacific',  'Amount' =>  '640.00', 'Quantity' => '32' },
  { 'Product' => "Uncle Bob's Organic",    'Region' => 'North America', 'Amount' =>  '315.60', 'Quantity' => '18' },
  { 'Product' => 'Northwoods Cranberry',   'Region' => 'North America', 'Amount' =>  '560.00', 'Quantity' => '20' },
  { 'Product' => 'Mishi Kobe Niku',        'Region' => 'Asia Pacific',  'Amount' => '4500.00', 'Quantity' => '30' },
  { 'Product' => 'Ikura',                  'Region' => 'Asia Pacific',  'Amount' => '1980.00', 'Quantity' => '36' },
  { 'Product' => 'Queso Cabrales',         'Region' => 'Europe',        'Amount' =>  '850.00', 'Quantity' => '25' },
  { 'Product' => 'Queso Manchego La',      'Region' => 'Europe',        'Amount' =>  '720.00', 'Quantity' => '30' },
  { 'Product' => 'Konbu',                  'Region' => 'Asia Pacific',  'Amount' =>  '180.00', 'Quantity' => '24' },
  { 'Product' => 'Tofu',                   'Region' => 'Asia Pacific',  'Amount' =>  '560.00', 'Quantity' => '40' },
  { 'Product' => 'Genen Shouyu',           'Region' => 'Asia Pacific',  'Amount' =>  '310.00', 'Quantity' => '26' },
  { 'Product' => 'Pavlova',                'Region' => 'Asia Pacific',  'Amount' =>  '825.00', 'Quantity' => '55' },
  { 'Product' => 'Alice Mutton',           'Region' => 'Europe',        'Amount' => '2340.00', 'Quantity' => '26' },
  { 'Product' => 'Carnarvon Tigers',       'Region' => 'Asia Pacific',  'Amount' => '6200.00', 'Quantity' => '31' },
  { 'Product' => 'Teatime Biscuits',       'Region' => 'Europe',        'Amount' =>  '291.60', 'Quantity' => '36' },
  { 'Product' => "Sir Rodney's Marmalade", 'Region' => 'Europe',        'Amount' => '1245.00', 'Quantity' => '45' },
  { 'Product' => "Sir Rodney's Scones",    'Region' => 'Europe',        'Amount' =>  '350.00', 'Quantity' => '50' },
]

# REPORT EXAMPLE
fns = RdlLibrary.load(lib_path)
rpt = ReportNative.new(fns, report_path)
rpt.add_data('Data', sales_data)

out_path = File.join(output_directory, 'sales-report.pdf')
rpt.export('pdf', out_path)
puts "Written: #{out_path}"
