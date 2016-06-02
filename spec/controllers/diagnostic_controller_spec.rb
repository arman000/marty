require 'spec_helper'

module Marty
  RSpec.describe DiagnosticController, type: :controller do
    before(:each) { @routes = Marty::Engine.routes }
    let(:json_response) { JSON.parse(response.body) }

    describe 'GET #index' do
      it 'returns http success' do
        get :index, testop: :version

        expect(response).to have_http_status(:success)
      end

      it 'returns the current version' do
        get :index, testop: :version

        aggregate_failures do
          expect(assigns('details').count).to eq(3)
          expect(assigns('details').third.methods)
            .to include(:name, :status, :description)
          expect(assigns('details').third.description).to eq(Marty::VERSION)
        end
      end

      it 'returns the appropriate json' do
        get :index, {format: :json, testop: :version}

        aggregate_failures do
          expect(json_response.first['diag_count']).to eq(3)
          expect(json_response.first['error_count']).to eq(0)
          expect(json_response
                 .find { |d| d['name'] == 'Marty Version' }['description'])
            .to eq(Marty::VERSION)
        end
      end
    end

    describe 'GET #version' do
      it 'returns http success' do
        get :version

        expect(response).to have_http_status(:success)
      end

      it 'returns the current version' do
        get :version

        aggregate_failures do
          expect(assigns('details').count).to eq(3)
          expect(assigns('details').third.methods)
            .to include(:name, :status, :description)
          expect(assigns('details').third.description).to eq(Marty::VERSION)
        end
      end

      it 'returns the appropriate json' do
        get :version, format: :json

        aggregate_failures do
          expect(json_response.first['diag_count']).to eq(3)
          expect(json_response.first['error_count']).to eq(0)
          expect(json_response
                 .find { |d| d['name'] == 'Marty Version' }['description'])
            .to eq(Marty::VERSION)
        end
      end
    end
  end
end
