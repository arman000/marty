RSpec.describe 'Authenticating with the API' do
  before do
    Rails.application.routes.draw do
      get '/api/test' => 'test#index'
    end
  end

  after do
    Rails.application.reload_routes!
  end

  context 'when the req has a valid api key and authorizations are nil' do
    let!(:api) { Marty::HttpApiAuth.create!(app_name: 'some_app', authorizations: nil) }

    it 'allows access' do
      credentials = authenticate_with_token(api.token)

      get '/api/test', headers: { 'Authorization' => credentials }

      expect(response).to be_successful
      expect(response.body).to eq({ 'message' => 'Hello world!' }.to_json)
    end
  end

  context 'when the req has a valid api key and authorizations are empty' do
    let!(:api) { Marty::HttpApiAuth.create!(app_name: 'some_app', authorizations: '') }

    it 'allows access' do
      credentials = authenticate_with_token(api.token)

      get '/api/test', headers: { 'Authorization' => credentials }

      expect(response).to be_successful
      expect(response.body).to eq({ 'message' => 'Hello world!' }.to_json)
    end
  end

  context 'when the req has a valid api key and authorizations are a wildcard' do
    let!(:api) { Marty::HttpApiAuth.create!(app_name: 'some_app', authorizations: '*') }

    it 'allows access' do
      credentials = authenticate_with_token(api.token)

      get '/api/test', headers: { 'Authorization' => credentials }

      expect(response).to be_successful
      expect(response.body).to eq({ 'message' => 'Hello world!' }.to_json)
    end
  end

  context 'when the req has a valid api key and authorizations match' do
    let(:authorizations) do
      [{ path: '/api/test', method: 'GET' }]
    end

    let!(:api) { Marty::HttpApiAuth.create!(app_name: 'some_app', authorizations: authorizations) }

    it 'allows access' do
      credentials = authenticate_with_token(api.token)

      get '/api/test', headers: { 'Authorization' => credentials }

      expect(response).to be_successful
      expect(response.body).to eq({ 'message' => 'Hello world!' }.to_json)
    end
  end

  context 'when the req has a valid api key, the path is allowed but the http method IS NOT ALLOWED' do
    let(:authorizations) do
      [{ path: '/api/test', method: 'POST' }]
    end

    let!(:api) { Marty::HttpApiAuth.create!(app_name: 'some_app', authorizations: authorizations) }

    it 'blocks access' do
      credentials = authenticate_with_token(api.token)

      get '/api/test', headers: { 'Authorization' => credentials }

      expect(response).to be_unauthorized
      expect(response.body).to include('HTTP Token: Access denied.')
    end
  end

  context 'when the req has a valid api key but authorizations DO NOT match' do
    let(:authorizations) do
      [{ path: '/api/only_this', method: 'GET' }]
    end

    let!(:api) { Marty::HttpApiAuth.create!(app_name: 'some_app', authorizations: authorizations) }

    it 'blocks access' do
      credentials = authenticate_with_token(api.token)

      get '/api/test', headers: { 'Authorization' => credentials }

      expect(response).to be_unauthorized
      expect(response.body).to include('HTTP Token: Access denied.')
    end
  end

  context 'with an invalid api key' do
    it 'does not allow access' do
      credentials = authenticate_with_token('Gobbledygook')

      get '/api/test', headers: { 'Authorization' => credentials }

      expect(response).to be_unauthorized
    end

    it 'does not allow access' do
      credentials = authenticate_with_token('')

      get '/api/test', headers: { 'Authorization' => credentials }

      expect(response).to be_unauthorized
    end
  end

  private

  TestController = Class.new(Marty::HttpApi::BaseController) do
    def index
      render json: { message: 'Hello world!' }
    end
  end

  def authenticate_with_token(token)
    ActionController::HttpAuthentication::Token.encode_credentials(token)
  end
end
