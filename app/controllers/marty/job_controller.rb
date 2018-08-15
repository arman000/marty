class Marty::JobController < ActionController::Base
  def download
    job_id = params["job_id"]

    promise = Marty::Promise.find_by_id(job_id)

    if promise
      format = promise.cformat

      # Force result so finalized object is built
      data = promise.result(true)

      # somewhat hacky: if result has "result" key, it's used as the
      # content.
      data = data["result"] || data
      title = promise.title
    else
      format = "json"
      data = {error: "Job not found: #{job_id}"}
      title = "error"
    end

    res, type, disposition, filename =
      Marty::ContentHandler.export(data, format, title)

    send_data(res,
              type:        type,
              filename:    filename,
              disposition: disposition,
              )
  end
end
