RSpec.describe Scheduler::Examples::SchedulableModel do

  before do
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

  # context "when it is set to perform" do

  #   it "creates an instance of the resource class" do
  #     resource = described_class.new job_attributes
  #     resource.perform
  #     expect(described_class.find(resource.id)).to_not be nil
  #   end

  #   it "calls the instanced job 'call' method" do
  #     resource = described_class.new job_attributes
  #     resource.perform
  #     expect(resource.reload.status).to be :completed
  #   end

  # end

end
