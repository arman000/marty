require 'spec_helper'
module Marty
  RSpec.describe DiagnosticController, type: :controller do
    before(:each) { @routes = Marty::Engine.routes }
    let(:json_response) { JSON.parse(response.body) }

    describe 'GET #op' do
      it 'returns http success' do
        get :op, format: :json, op: 'version'
        expect(response).to have_http_status(:success)
      end

      it 'a request injects the request object into Diagnostic classes' do
        get :op, format: :json, op: 'version'
        expect(Diagnostic::Reporter.request).not_to eq(nil)
      end

      it 'returns the current version JSON' do
        get :op, format: :json, op: 'version', data: 'true'

        # generate version data and declare all values consistent
        versions = Diagnostic::Version.generate.each_with_object({}){
          |(n, v),h|
          h[n] = v.each{|t, r| r['consistent'] = true}
        }

        expected = {
          'data' => {
            'Diagnostic::Version' => versions
          }
        }

        expect(assigns('result')).to eq(expected)
      end
    end
  end
end
