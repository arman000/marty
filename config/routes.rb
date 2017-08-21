Marty::Engine.routes.draw do
  match via: [:get, :post], "rpc/evaluate(.:format)" => "rpc", as: :rpc
  get "job/download" => "job", as: :job
  match via: [:get, :post], "report(.:format)" => "report#index", as: :report

  %i(index version environment).each do |action|
    get  "diag/#{action}", controller: 'diagnostic'
  end

  %i(index version environment).each do |action|
    get  "diagnostic/#{action}", controller: 'diagnostic'
  end
end
