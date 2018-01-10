class Marty::Diagnostic::Request
  def self.request
    raise 'Request object has not been been injected into #{name}' unless
      @@request

    @@request
  end

  def self.request= req
    @@request = req
  end

  def self.params
    request.params
  end

  def self.scope
    params[:scope]
  end

  def self.op
    params[:op]
  end

  def self.ssl?
    request.port == 443
  end
end
