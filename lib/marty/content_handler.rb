module Marty::ContentHandler
  GEN_FORMATS = {
    "csv"  => ['text/csv',                 'download'],
    "zip"  => ['application/zip',          'download'],
    "xlsx" => ['application/vnd.ms-excel', 'download'],
    "html" => ['text/html',                'inline'],
    "txt"  => ['text/plain',               'inline'],
    "json" => ['application/json',         'download'],

    # hacky: default format is JSON
    nil    => ['application/json',         'download'],
  }

  def self.log_and_raise(err)
    Marty::Util.logger.error err
    raise err
  end

  def self.export(data, format, name)
    begin
      case format
      when "csv"
        # Somewhat hacky, if data is string => pass through as CSV.
        # Should generalize to other data types, not just CSV.
        res = data.is_a?(String) ? data : Marty::DataExporter.to_csv(data)
      when "xlsx"
        res = Marty::Xl.spreadsheet(data).to_stream.read
      when "zip"
        res = to_zip(data)
      when nil, "json"
        res, format = data.to_json, "json"
      else
        res, format = {error: "Unknown format: #{format}"}.to_json, "json"
      end
    rescue => exc
      res, format =
        {error: "Failed conversion #{format}: #{exc}"}.to_json, "json"
    end

    type, disposition = GEN_FORMATS[format]

    return [res, type, disposition, "#{name}.#{format}"]
  end

  private

  def self.sanitize_filename(filename)
    filename.strip.
      gsub(/[\\\/]/, '_').
      gsub(/[^[:print:]]/, '_')
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

  def self.to_zip(data)
    raise "Can't convert non-array data to zip format: #{data.class}" unless
      data.is_a?(Array)

    res = Zip::OutputStream.write_buffer do |stream|
      to_zip_stream(stream, [], data)
    end
    res.string
  end
end
