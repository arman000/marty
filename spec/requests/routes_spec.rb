require 'spec_helper'

describe 'Marty Rails engine routes', type: :request do
  it 'can reach the rpc endpoint' do
    get marty.rpc_path(:evaluate, format: :json)
    post marty.rpc_path(:evaluate, format: :json)
  end

  it 'can reach the jobs endpoint' do
    get marty.job_path(:download)
  end
end
