require 'spec_helper'
require 'marty'
require 'delorean_lang'
require 'benchmark'
require 'job_helper'
require 'support/empty_job'

describe Marty::DelayedJobController, slow: false do
  before(:each) { @routes = Marty::Engine.routes }

  describe "#trigger" do
    before do
      @job = ::Delayed::Job.enqueue EmptyJob.new
    end

    it "should be able to execute existing job" do
      expect(::Delayed::Job.exists?(@job.id)).to be true
      post :trigger, params: { id: @job.id }
      expect(response).to have_http_status(:ok)
      expect(::Delayed::Job.exists?(@job.id)).to be false
    end

    it "should return ok if triggered job is locked" do
      @job.update!(locked_at: Time.zone.now)
      post :trigger, params: { id: @job.id }
      expect(response).to have_http_status(:ok)
    end

    it "should return ok if triggered job is missing" do
      @job.destroy!
      post :trigger, params: { id: @job.id }
      expect(response).to have_http_status(:ok)
    end
  end
end
