class FailingExecutableClass < Scheduler::Examples::ExecutableClass
  def call(*args)
    @job.progress! 25
    @job.error!('Example of error.')
    @job.progress! 50
  end
end

RSpec.describe Scheduler::Examples::SchedulableModel do

  after do
    Scheduler.configuration.job_class.delete_all
  end

  let(:job_attributes) do
    Hash[executable_class: 'Scheduler::Examples::ExecutableClass', args: []]
  end

  it "can be scheduled to execute" do
    resource = described_class.new job_attributes
    expect(resource.respond_to? :schedule).to be true
  end

  it "can be progressed to a given amount" do
    resource = described_class.create job_attributes
    progress = rand(51.0..90.0)
    resource.progress! progress
    expect(resource.reload.progress).to eq progress
  end

  it "can be progressed by a given amount" do
    resource = described_class.create job_attributes
    progress = rand(1.0..10.0)
    previous_progress = resource.progress
    resource.progress_by! progress
    expect(resource.reload.progress).to eq (previous_progress + progress)
  end

  context "when it is scheduled" do

    it "starts with status :queued" do
      resource = described_class.new job_attributes
      resource.schedule
      expect(resource.status).to eq :queued
    end

    it "sets field :scheduled_at with current time" do
      resource = described_class.new job_attributes
      resource.schedule
      expect(resource.scheduled_at).to be_present
    end

    it "resets fields :logs, :progress, :error, :backtrace, :completed_at, :executed_at" do
      resource = described_class.new job_attributes
      resource.schedule
      expect(resource.logs).to be_empty
      expect(resource.progress).to eq 0.0
      expect(resource.error).to be_nil
      expect(resource.backtrace).to be_nil
      expect(resource.completed_at).to be_nil
      expect(resource.executed_at).to be_nil
    end

    context "when a scheduler main process is running" do

      before :context do
        Scheduler.configuration.polling_interval = 1
        Scheduler.start
      end

      after :context do
        Scheduler.stop
      end

      it "performs the scheduled job after the configured amount of seconds" do
        sleep 1
        resource = described_class.new job_attributes
        resource.schedule
        sleep 2
        expect(resource.reload.status).to be :completed
      end

    end

  end

  context "when it executes a failing class" do
    it "immediately stops execution if an error is thrown" do
      resource = described_class.new job_attributes.merge executable_class: 'FailingExecutableClass'
      resource.perform
      expect(resource.reload.status).to be :error
      expect(resource.reload.progress).to be 25.0
    end
  end

end
