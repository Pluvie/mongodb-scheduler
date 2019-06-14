require_relative '../scheduler'

namespace :scheduler do

  desc 'Scheduler Start'
  task :start do |t, args|
     Scheduler.start
  end
  
  desc 'Scheduler Stop'
  task :stop do |t, args|
     Scheduler.stop
  end

  desc 'Scheduler Restart'
  task :restart do |t, args|
     Scheduler.restart
  end

end
