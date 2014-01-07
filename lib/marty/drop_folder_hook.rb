class Marty::DropFolderHook
  def initialize(login)
    @login = login
  end

  def drop_base
    Rails.configuration.marty.drop_base || "/tmp"
  end

  def drop_path
    "#{drop_base}/#{@login}"
  end

  def dpath(title, i)
    post  = i==0 ? "" : "(#{i})"
    "#{drop_path}/#{title}#{post}"
  end

  def log_and_raise(err)
    Marty::Util.logger.error err
    raise err
  end

  def save(resarr, base)
    log_and_raise "non array result key: #{resarr.class}" unless
      resarr.is_a?(Array)

    resarr.each { |r|
      title, format, result = r["title"], r["format"], r["result"]

      log_and_raise "Result has no title" unless title
      log_and_raise "Result has no format" unless format
      log_and_raise "Result has no result" unless result

      log_and_raise "bad format #{format}" unless
      ["csv", "xlsx", "background"].member?(format)

      if format=="background"
        dp = "#{base}/#{title}"
        Dir.mkdir dp
        save(result, dp)
        next
      end

      # FIXME: handle case where same title is used more than once.

      # FIXME: handle cases where to csv/xlsx fails.

      open("#{base}/#{title}.#{format}", "w") { |f|
        if format == "csv"
          csv = Marty::DataExporter.to_csv(result)
          f.puts csv
        else
          xlsx_report = Marty::Xl.spreadsheet(result)
          xlsx_report.serialize(f)
        end
      }
    }
  end

  def run(r)
    # FIXME: shouldn't we write out an error file if we fail somewhere
    # in this process??

    log_and_raise "Drop path doesn't exist: #{drop_path}" unless
      File.directory?(drop_path)

    log_and_raise "non-hash result: #{r.class}" unless
      r.is_a?(Hash)

    title, result = r["title"], r["result"]

    log_and_raise "Result has no title" unless title
    log_and_raise "Result has no result" unless result

    log_and_raise "Result is malformed #{result.class}" unless
      result.is_a?(Array)

    c = (0..1000).detect { |i|
      begin
        p = dpath(title, i)
        Dir.mkdir(p)
      rescue Errno::EEXIST
        next
      end
    }

    log_and_raise "Could not create result path: #{dpath(title, 0)}" unless c
    save(result, dpath(title, c))
  end
end
