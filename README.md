# Scheduler
This gem aims to create a simple yet efficient framework to handle job scheduling and execution. It is targeted for MongoDB database.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'mongodb-scheduler'
```

And then execute:
```bash
$ bundle install
```

## Usage
This gem adds a `Scheduler` module which can be started, stopped or restarted with their corresponding command:
```bash
$ scheduler start
$ scheduler stop
$ scheduler restart
```
A `Scheduler` is a process that keeps running looking for jobs to perform. The jobs are documents of a specific collection that you can specify in the scheduler configuration file. You can specify your own model to act as a schedulable entity, as long as it includes the `Schedulable` module. The other configuration options are explained in the template file `lib/scheduler/templates/scheduler.rb` file.

As an example, the gem comes with a `Scheduler::Examples::SchedulableModel` which is a bare class that just includes the `Scheduler::Schedulable` module, and also an `Scheduler::Examples::ExecutableClass` class which is a bare implementation of an executable class.
An executable class is just a plain Ruby class which must implement a `call` method which accepts one argument. This argument is an instance of the schedulable model that you configured.

First start by running the scheduler:
```bash
$ scheduler start
```

You can then queue jobs by calling:
```ruby
YourSchedulableModel.schedule('YourExecutableClass', args...) # to queue
```
Both methods create a document of `YourSchedulableModel` and put it in queue.
The __perform_now__ method skips the scheduler and performs the job immediately, instead the __perform_later__ leaves the performing task to the scheduler.

If you want to stop the scheduler, just run:
```bash
$ scheduler stop
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
