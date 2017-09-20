Marty::Engine.routes.draw do
  match via: [:get, :post], "rpc/evaluate(.:format)" => "rpc", as: :rpc
  match via: [:get, :post], "report(.:format)" => "report#index", as: :report
  get "job/download" => "job", as: :job

  %i(index version environment).each do |action|
    get "diag/#{action}", controller: 'diagnostic'
  end

  %i(index version environment).each do |action|
    get "diagnostic/#{action}", controller: 'diagnostic'
  end
end
