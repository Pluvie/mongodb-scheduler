RSpec.describe Scheduler do
  
  it "has a version number" do
    expect(Scheduler::VERSION).not_to be nil
  end

  it "can be started and stopped" do
    Scheduler.start
    sleep 1
    expect { Process.getpgid Scheduler.pid }.to_not raise_error
    expect { Scheduler.stop }.to_not raise_error
    expect(Scheduler.pid).to be nil
  end

end
