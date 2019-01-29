class Marty::ReportController < Marty::ApplicationController
  def index
    format, req_disposition, title =
      params[:format], params[:disposition], params[:reptitle]

    raise "bad format" unless Marty::ContentHandler::GEN_FORMATS.member?(format)

    data = Marty::ReportForm.run_eval(params)

    # hacky: shouldn't have error parsing logic here
    format = "json" if data.is_a?(Hash) && (data[:error] || data["error"])

    # hack for testing -- txt -> csv
    exp_format = format == "txt" ? "csv" : format

    res, type, disposition, filename =
      Marty::ContentHandler
        .export(data, exp_format, title)

    # hack for testing -- set content-type
    type = "text/plain" if format == "txt" && type =~ /csv/

    return send_data(res,
                     type:        type,
                     filename:    filename,
                     disposition: req_disposition || disposition,
                    )
  end
end
