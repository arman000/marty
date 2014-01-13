module Marty::ContentHandler
  GEN_FORMATS = {
    "csv" 	=> ['text/csv',			'download'],
    "zip" 	=> ['application/zip',		'download'],
    "xlsx" 	=> ['application/vnd.ms-excel',	'download'],
    "html" 	=> ['text/html',		'inline'],
    "txt"	=> ['text/plain',		'inline'],
    "json"	=> ['application/json',		'download'],

    # hacky: default format is JSON
    nil		=> ['application/json',		'download'],
  }

  def self.log_and_raise(err)
    Marty::Util.logger.error err
    raise err
  end

  def self.export(data, format, name)
    begin
      if format == "csv"
        res = Marty::DataExporter.to_csv(data)
      elsif format == "xlsx"
        res = Marty::Xl.spreadsheet(data).to_stream.read
      elsif format == "zip"
        res = to_zip(data, name)
      elsif format.nil? || format == "json"
        res = data.to_json
      else
        res = {error: "Unknown format: #{format}"}
        format = "json"
      end
    rescue => exc
      res = {error: "Conversion for format #{format} failed: #{exc}"}
      format = "json"
    end

    type, disposition = GEN_FORMATS[format]

    return [res, type, disposition, "#{name}.#{format}"]
  end

  private

  def self.sanitize_filename(filename)
    filename.strip do |name|
      name.gsub!(/^.*(\\|\/)/, '')

      # Strip out the non-ascii character
      name.gsub!(/[^0-9A-Za-z.\-]/, '_')
    end
  end

  def self.uniq_filename(filename, fset)
    (0..1000).each { |i|
      post = i==0 ? "" : " (#{i})"
      fn = filename + post
      return fn unless fset.member? fn
    }
    filename
  end

  def self.to_zip_stream(stream, path, data)
    fset = Set.new

    data.each { |r|
      title, format, result = r["title"], r["format"], r["result"]

      log_and_raise "Result has no title" unless title
      log_and_raise "Result has no result" unless result

      if format == "zip"
        to_zip_stream(stream, path + [title], result)
        next
      end

      res_data, _type, _disposition, res_name = export(result, format, title)

      filename = uniq_filename(sanitize_filename(res_name), fset)
      fset.add filename

      stream.put_next_entry((path + [filename]).join('/'))
      stream.write res_data
    }
  end

  def self.to_zip(data, name)
    raise "Can't convert non-array data to zip format: #{data.class}" unless
      data.is_a?(Array)

    res = Zip::OutputStream.write_buffer do |stream|
      to_zip_stream(stream, [name], data)
    end
    res.string
  end
end
