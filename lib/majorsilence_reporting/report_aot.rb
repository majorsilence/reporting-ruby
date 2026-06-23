# frozen_string_literal: true

require 'fileutils'
require 'tempfile'

# Report class for use with the AOT or self-contained RdlCmd binary.
#
# Unlike Report, this class does not accept a path_to_dotnet argument.
# rdl_cmd_path must point to the native AOT or self-contained executable
# (e.g. RdlCmd on Linux/macOS, RdlCmd.exe on Windows) — no .NET runtime is required.
#
# Usage:
#   require 'majorsilence_reporting/report_aot'
#
#   rpt = ReportAot.new('/path/to/report.rdl', '/path/to/RdlCmd')
#   rpt.set_parameter('Country', 'Germany')
#   rpt.set_connection_string('Data Source=myserver.db')
#   rpt.export('pdf', '/tmp/output.pdf')
#
# Supported export types: "pdf", "csv", "xlsx", "xlsx_table", "xml", "rtf", "tif", "tifb", "html", "mht".
class ReportAot
  VALID_TYPES  = %w[pdf csv xlsx xlsx_table xml rtf tif tifb html mht].freeze
  BINARY_TYPES = %w[pdf tif tifb rtf xlsx xlsx_table].freeze

  def initialize(report_path, rdl_cmd_path)
    @report_path       = report_path
    @rdl_cmd_path      = rdl_cmd_path
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
  #   type        - output format: "pdf", "csv", "xlsx", "xlsx_table", "xml",
  #                 "rtf", "tif", "tifb", "html", "mht". Defaults to "pdf".
  #   export_path - destination file path
  def export(type, export_path)
    type = 'pdf' unless VALID_TYPES.include?(type)

    tmp         = Tempfile.new('majorsilencereporting')
    tmp_path    = tmp.path
    tmp_dir     = File.dirname(tmp_path)
    tmp.close
    FileUtils.cp(@report_path, tmp_path)

    rdl_arg = "/f#{tmp_path}"
    @parameters.each_with_index do |(key, value), i|
      rdl_arg += (i.zero? ? '?' : '&') + "#{key}=#{value}"
    end

    cmd = [@rdl_cmd_path, rdl_arg, "/t#{type}", "/o#{tmp_dir}"]
    cmd << "/c#{@connection_string}" if @connection_string

    system(*cmd) or raise "RdlCmd failed (exit #{$?.exitstatus})"

    tmp_out = File.join(tmp_dir, File.basename(tmp_path) + ".#{type}")
    FileUtils.cp(tmp_out, export_path)
    File.delete(tmp_path)
    File.delete(tmp_out)
  end

  # Render the report and return the output.
  # Returns binary String for pdf/tif/tifb/rtf/xlsx; UTF-8 String for text formats.
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
