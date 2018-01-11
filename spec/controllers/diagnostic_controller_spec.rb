require 'spec_helper'

# used for testing controller inheritance
module Test
  module Diagnostic; end
end

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
            'Version' => versions
          }
        }

        expect(assigns('result')).to eq(expected)
      end
    end

    describe 'Inheritance behavior' do
      it 'appends namespace to reporter and resolves in order of inheritance' do
        class Test::SomeController < DiagnosticController; end
        expect(Diagnostic::Reporter.namespaces).to include('Test')

        class Test::Diagnostic::Version; end
        expect(Diagnostic::Reporter.resolve_diagnostic('Version').name).
          to include('Test')

        Diagnostic::Reporter.namespaces.shift
      end
    end
  end
end
