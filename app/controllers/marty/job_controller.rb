class Marty::JobController < ActionController::Base
  def download
    job_id = params["job_id"]

    promise = Marty::Promise.find_by_id(job_id)

    return "Job not found: #{job_id}" unless promise

    format = promise.cformat
    data = promise.result["result"]

    res, type, disposition, filename =
      Marty::ContentHandler.export(data, format, promise.title)

    return send_data(res,
                     type: 		type,
                     filename: 		filename,
                     disposition: 	disposition,
                     )
  end

end
