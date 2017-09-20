require 'spec_helper'

module Marty
  RSpec.describe DiagnosticController, type: :controller do
    before(:each) { @routes = Marty::Engine.routes }
    let(:json_response) { JSON.parse(response.body) }

    describe 'GET #index' do
      it 'returns http success' do
        get :index, params: { testop: :version }

        expect(response).to have_http_status(:success)
      end

      it 'returns the current version' do
        get :index, params: { testop: :version }

        aggregate_failures do
          expect(assigns('details').count).to eq(3)
          expect(assigns('details').third.methods)
            .to include(:name, :status, :description)
          expect(assigns('details').third.description).to eq(Marty::VERSION)
        end
      end

      it 'returns the appropriate json' do
        get :index, params: { testop: :version }, format: :json

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

    describe 'GET #environment' do
      it 'returns http success' do
        get :environment

        expect(response).to have_http_status(:success)
      end

      it 'returns the environment details' do
        get :environment

        aggregate_failures do
          expect(assigns('details').count).to eq(9)
          expect(assigns('details').first.methods)
            .to include(:name, :status, :description)
          expect(assigns('details').first.description).to eq('test')
        end
      end

      it 'returns the appropriate json' do
        get :environment, format: :json

        aggregate_failures do
          expect(json_response.first['diag_count']).to eq(9)
          expect(json_response.first['error_count']).to eq(0)
          expect(json_response
                 .find { |d| d['name'] == 'Environment' }['description'])
            .to eq('test')
        end
      end
    end

  end
end
