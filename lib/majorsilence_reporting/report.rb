# frozen_string_literal: true

require 'fileutils'
require 'tempfile'

# Generates reports via the RdlCmd .NET command-line tool.
#
# Requires a .NET runtime on the host. For self-contained or AOT builds
# that need no runtime, use ReportAot instead.
#
# Usage:
#   require 'majorsilence_reporting/report'
#   # or: require 'majorsilence_reporting'  (loads all three wrappers)
#
#   rpt = Report.new('/path/to/report.rdl', '/path/to/RdlCmd.dll', 'dotnet')
#   rpt.set_connection_string('Data Source=/path/to/db.sqlite')
#   rpt.set_parameter('Country', 'Germany')
#   rpt.export('pdf', '/tmp/output.pdf')
#   data = rpt.export_to_memory('pdf')
#
# Supported export types: "pdf", "csv", "xlsx", "xml", "rtf", "tif", "html"
class Report
  VALID_TYPES  = %w[pdf csv xlsx xml rtf tif html].freeze
  BINARY_TYPES = %w[pdf tif rtf].freeze

  def initialize(report_path, rdl_cmd_path, path_to_dotnet = nil)
    @report_path       = report_path
    @rdl_cmd_path      = rdl_cmd_path
    @path_to_dotnet    = path_to_dotnet
    @parameters        = {}
    @connection_string = nil
  end

  # Set a report parameter value.
  #   name  - parameter name as declared in the RDL
  #   value - parameter value (string)
  def set_parameter(name, value)
    @parameters[name] = value
  end

  # Override the connection string defined in the RDL.
  def set_connection_string(connection_string)
    @connection_string = connection_string
  end

  # Render the report and save it to export_path.
  #   type        - output format: "pdf", "csv", "xlsx", "xml", "rtf", "tif", "html". Defaults to "pdf".
  #   export_path - destination file path
  def export(type, export_path)
    type = 'pdf' unless VALID_TYPES.include?(type)

    tmp      = Tempfile.new('majorsilencereporting')
    tmp_path = tmp.path
    tmp_dir  = File.dirname(tmp_path)
    tmp.close
    FileUtils.cp(@report_path, tmp_path)

    rdl_arg = "/f#{tmp_path}"
    @parameters.each_with_index do |(key, value), i|
      rdl_arg += (i.zero? ? '?' : '&') + "#{key}=#{value}"
    end

    cmd = []
    cmd << @path_to_dotnet if @path_to_dotnet
    cmd += [@rdl_cmd_path, rdl_arg, "/t#{type}", "/o#{tmp_dir}"]
    cmd << "/c#{@connection_string}" if @connection_string

    system(*cmd) or raise "RdlCmd failed (exit #{$?.exitstatus})"

    tmp_out = File.join(tmp_dir, File.basename(tmp_path) + ".#{type}")
    FileUtils.cp(tmp_out, export_path)
    File.delete(tmp_path)
    File.delete(tmp_out)
  end

  # Render the report and return the output.
  # Returns binary String for pdf/tif/rtf; UTF-8 String for text formats.
  #   type - output format (defaults to "pdf" if unrecognised)
  def export_to_memory(type)
    type = 'pdf' unless VALID_TYPES.include?(type)

    tmp      = Tempfile.new('majorsilencereporting')
    tmp_path = tmp.path
    tmp.close
    tmp.unlink

    export(type, tmp_path)

    data = BINARY_TYPES.include?(type) ? File.binread(tmp_path) : File.read(tmp_path, encoding: 'UTF-8')
    File.delete(tmp_path) if File.exist?(tmp_path)
    data
  end
end
