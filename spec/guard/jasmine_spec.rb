require 'spec_helper'

describe Guard::Jasmine do

  let(:guard) { Guard::Jasmine.new }

  let(:runner) { Guard::Jasmine::Runner }
  let(:inspector) { Guard::Jasmine::Inspector }
  let(:formatter) { Guard::Jasmine::Formatter }

  let(:defaults) { Guard::Jasmine::DEFAULT_OPTIONS }

  before do
    inspector.stub(:clean).and_return { |specs| specs }
    runner.stub(:run).and_return [true, []]
    formatter.stub(:notify)
  end

  describe '#initialize' do
    context 'when no options are provided' do
      it 'sets a default :jasmine_url option' do
        guard.options[:jasmine_url].should eql 'http://localhost:3000/jasmine'
      end

      it 'sets a default :phantomjs_bin option' do
        guard.options[:phantomjs_bin].should eql '/usr/local/bin/phantomjs'
      end

      it 'sets a default :timeout option' do
        guard.options[:timeout].should eql 10000
      end

      it 'sets a default :all_on_start option' do
        guard.options[:all_on_start].should be_true
      end

      it 'sets a default :notifications option' do
        guard.options[:notification].should be_true
      end

      it 'sets a default :hide_success option' do
        guard.options[:hide_success].should be_false
      end

      it 'sets a default :max_error_notify option' do
        guard.options[:max_error_notify].should eql 3
      end

      it 'sets a default :keep_failed option' do
        guard.options[:keep_failed].should be_true
      end

      it 'sets a default :all_after_pass option' do
        guard.options[:all_after_pass].should be_true
      end

      it 'sets a default :specdoc option' do
        guard.options[:specdoc].should eql :failure
      end

      it 'sets a default :console option' do
        guard.options[:console].should eql :failure
      end

      it 'sets a default :focus option' do
        guard.options[:focus].should eql true
      end

      it 'sets last run failed to false' do
        guard.last_run_failed.should be_false
      end

      it 'sets last failed paths to empty' do
        guard.last_failed_paths.should be_empty
      end
    end

    context 'with other options than the default ones' do
      let(:guard) { Guard::Jasmine.new(nil, { :jasmine_url      => 'http://192.168.1.5/jasmine',
                                              :phantomjs_bin    => '~/bin/phantomjs',
                                              :timeout          => 20000,
                                              :all_on_start     => false,
                                              :notification     => false,
                                              :max_error_notify => 5,
                                              :hide_success     => true,
                                              :keep_failed      => false,
                                              :all_after_pass   => false,
                                              :specdoc          => :always,
                                              :focus            => false,
                                              :console          => :always }) }

      it 'sets the :jasmine_url option' do
        guard.options[:jasmine_url].should eql 'http://192.168.1.5/jasmine'
      end

      it 'sets the :phantomjs_bin option' do
        guard.options[:phantomjs_bin].should eql '~/bin/phantomjs'
      end

      it 'sets the :phantomjs_bin option' do
        guard.options[:timeout].should eql 20000
      end

      it 'sets the :all_on_start option' do
        guard.options[:all_on_start].should be_false
      end

      it 'sets the :notifications option' do
        guard.options[:notification].should be_false
      end

      it 'sets the :hide_success option' do
        guard.options[:hide_success].should be_true
      end

      it 'sets the :max_error_notify option' do
        guard.options[:max_error_notify].should eql 5
      end

      it 'sets the :keep_failed option' do
        guard.options[:keep_failed].should be_false
      end

      it 'sets the :all_after_pass option' do
        guard.options[:all_after_pass].should be_false
      end

      it 'sets the :specdoc option' do
        guard.options[:specdoc].should eql :always
      end

      it 'sets the :console option' do
        guard.options[:console].should eql :always
      end

      it 'sets the :focus option' do
        guard.options[:focus].should eql false
      end
    end

    context 'with illegal options' do
      let(:guard) { Guard::Jasmine.new(nil, defaults.merge({ :specdoc => :wrong })) }

      it 'sets default :specdoc option' do
        guard.options[:specdoc].should eql :failure
      end
    end
  end

  describe '.start' do
    context 'with a missing PhantomJS binary' do
      before do
        guard.stub(:`).and_return nil
      end

      it 'shows a message that the binary is missing' do
        formatter.should_receive(:error).with "PhantomJS binary doesn't exist at /usr/local/bin/phantomjs"
        expect { guard.start }.to throw_symbol :task_has_failed
      end

      it 'throws :task_has_failed' do
        expect { guard.start }.to throw_symbol :task_has_failed
      end

      context 'with enabled notifications' do
        it 'shows a notification that the binary is missing' do
          formatter.should_receive(:notify).with("PhantomJS binary doesn't exist at /usr/local/bin/phantomjs",
                                                 :title    => 'PhantomJS binary missing',
                                                 :image    => :failed,
                                                 :priority => 2)
          expect { guard.start }.to throw_symbol :task_has_failed
        end
      end
    end

    context 'with a wrong PhantomJS version' do
      before do
        guard.stub(:`).and_return '1.2.0'
      end

      it 'shows a message that the version is wrong' do
        formatter.should_receive(:error).with "PhantomJS binary at /usr/local/bin/phantomjs must be at least version 1.3.0"
        expect { guard.start }.to throw_symbol :task_has_failed
      end

      it 'throws :task_has_failed' do
        expect { guard.start }.to throw_symbol :task_has_failed
      end

      context 'with enabled notifications' do
        it 'shows a notification that the version is wrong' do
          formatter.should_receive(:notify).with("PhantomJS binary at /usr/local/bin/phantomjs must be at least version 1.3.0",
                                                 :title    => 'Wrong PhantomJS version',
                                                 :image    => :failed,
                                                 :priority => 2)
          expect { guard.start }.to throw_symbol :task_has_failed
        end
      end
    end

    context 'with a valid PhantomJS binary' do
      before do
        guard.stub(:phantomjs_bin_valid?).and_return true
      end

      context 'with the Jasmine runner available' do
        let(:http) { mock('http') }

        before do
          http.stub_chain(:request, :code).and_return 200
          Net::HTTP.stub(:start).and_yield http
        end

        it 'does show that the runner is available' do
          formatter.should_receive(:info).with "Jasmine test runner is available at http://localhost:3000/jasmine"
          guard.start
        end
      end

      context 'without the Jasmine runner available' do
        let(:http) { mock('http') }

        context 'because the connection is refused' do
          before do
            Net::HTTP.stub(:start).and_raise Errno::ECONNREFUSED
          end

          it 'does show that the runner is not available' do
            formatter.should_receive(:error).with "Jasmine test runner isn't available at http://localhost:3000/jasmine"
            guard.start
          end
        end

        context 'because the http status is not OK' do
          before do
            http.stub_chain(:request, :code).and_return 404
            Net::HTTP.stub(:start).and_yield http
          end

          it 'does show that the runner is not available' do
            formatter.should_receive(:error).with "Jasmine test runner isn't available at http://localhost:3000/jasmine"
            guard.start
          end
        end

        context 'with notifications enabled' do
          before do
            Net::HTTP.stub(:start).and_raise Errno::ECONNREFUSED
          end

          it 'shows a failing system notification' do
            formatter.should_receive(:notify).with("Jasmine test runner isn't available at http://localhost:3000/jasmine",
                                                   :title    => "Jasmine test runner isn't available",
                                                   :image    => :failed,
                                                   :priority => 2)
            guard.start
          end
        end
      end

      context 'with :all_on_start set to true' do
        let(:guard) { Guard::Jasmine.new(nil, { :all_on_start => true }) }

        context 'with the Jasmine runner available' do
          before do
            guard.stub(:jasmine_runner_available?).and_return true
          end

          it 'triggers .run_all' do
            guard.should_receive(:run_all)
            guard.start
          end
        end

        context 'without the Jasmine runner available' do
          before do
            guard.stub(:jasmine_runner_available?).and_return false
          end

          it 'does not triggers .run_all' do
            guard.should_not_receive(:run_all)
            guard.start
          end
        end
      end

      context 'with :all_on_start set to false' do
        let(:guard) { Guard::Jasmine.new(nil, { :all_on_start => false }) }

        before do
          guard.stub(:jasmine_runner_available?).and_return true
        end

        it 'does not trigger .run_all' do
          guard.should_not_receive(:run_all)
          guard.start
        end
      end
    end
  end

  describe '.reload' do
    before do
      guard.last_run_failed   = true
      guard.last_failed_paths = ['spec/javascripts/a.js.coffee']
    end

    it 'sets last run failed to false' do
      guard.reload
      guard.last_run_failed.should be_false
    end

    it 'sets last failed paths to empty' do
      guard.reload
      guard.last_failed_paths.should be_empty
    end
  end

  describe '.run_all' do
    it 'starts the Runner with the spec dir' do
      runner.should_receive(:run).with(['spec/javascripts'], defaults).and_return [['spec/javascripts/a.js.coffee'], true]

      guard.run_all
    end

    context 'with all specs passing' do
      before do
        guard.last_failed_paths = ['spec/javascripts/a.js.coffee']
        guard.last_run_failed   = true
        runner.stub(:run).and_return [true, []]
      end

      it 'sets the last run failed to false' do
        guard.run_all
        guard.last_run_failed.should be_false
      end

      it 'clears the list of failed paths' do
        guard.run_all
        guard.last_failed_paths.should be_empty
      end
    end

    context 'with failing specs' do
      before do
        runner.stub(:run).and_return [false, []]
      end

      it 'throws :task_has_failed' do
        expect { guard.run_all }.to throw_symbol :task_has_failed
      end
    end

  end

  describe '.run_on_change' do
    it 'passes the paths to the Inspector for cleanup' do
      inspector.should_receive(:clean).twice.with(['spec/javascripts/a.js.coffee',
                                                   'spec/javascripts/b.js.coffee'])

      guard.run_on_change(['spec/javascripts/a.js.coffee',
                           'spec/javascripts/b.js.coffee'])
    end

    it 'clears the inspector' do
      inspector.should_receive(:clear)
      guard.run_on_change(['spec/javascripts/b.js.coffee'])
    end

    it 'returns false when no valid paths are passed' do
      inspector.should_receive(:clean).and_return []
      guard.run_on_change(['spec/javascripts/b.js.coffee'])
    end

    it 'starts the Runner with the cleaned files' do
      inspector.should_receive(:clean).twice.with(['spec/javascripts/a.js.coffee',
                                                   'spec/javascripts/b.js.coffee']).and_return ['spec/javascripts/a.js.coffee']

      runner.should_receive(:run).with(['spec/javascripts/a.js.coffee'], defaults).and_return [['spec/javascripts/a.js.coffee'], true]

      guard.run_on_change(['spec/javascripts/a.js.coffee', 'spec/javascripts/b.js.coffee'])
    end

    context 'with :keep_failed enabled' do
      let(:guard) { Guard::Jasmine.new(nil, { :keep_failed => true }) }

      before do
        guard.last_failed_paths = ['spec/javascripts/b.js.coffee']
      end

      it 'appends the last failed paths to the current run' do
        runner.should_receive(:run).with(['spec/javascripts/a.js.coffee',
                                          'spec/javascripts/b.js.coffee'], defaults)

        guard.run_on_change(['spec/javascripts/a.js.coffee'])
      end
    end

    context 'with only success specs' do
      before do
        guard.last_failed_paths = ['spec/javascripts/a.js.coffee']
        guard.last_run_failed   = true
        runner.stub(:run).and_return [true, []]
      end

      it 'sets the last run failed to false' do
        guard.run_on_change(['spec/javascripts/a.js.coffee'])
        guard.last_run_failed.should be_false
      end

      it 'removes the passed specs from the list of failed paths' do
        guard.run_on_change(['spec/javascripts/a.js.coffee'])
        guard.last_failed_paths.should be_empty
      end

      context 'when :all_after_pass is enabled' do
        let(:guard) { Guard::Jasmine.new(nil, { :all_after_pass => true }) }

        it 'runs all specs' do
          guard.should_receive(:run_all)
          guard.run_on_change(['spec/javascripts/a.js.coffee'])
        end
      end

      context 'when :all_after_pass is enabled' do
        let(:guard) { Guard::Jasmine.new(nil, { :all_after_pass => false }) }

        it 'does not run all specs' do
          guard.should_not_receive(:run_all)
          guard.run_on_change(['spec/javascripts/a.js.coffee'])
        end
      end
    end

    context 'with failing specs' do
      before do
        guard.last_run_failed = false
        runner.stub(:run).and_return [false, ['spec/javascripts/a.js.coffee']]
      end

      it 'throws :task_has_failed' do
        expect { guard.run_on_change(['spec/javascripts/a.js.coffee']) }.to throw_symbol :task_has_failed
      end

      it 'sets the last run failed to true' do
        expect { guard.run_on_change(['spec/javascripts/a.js.coffee']) }.to throw_symbol :task_has_failed
        guard.last_run_failed.should be_true
      end

      it 'appends the failed spec to the list of failed paths' do
        expect { guard.run_on_change(['spec/javascripts/a.js.coffee']) }.to throw_symbol :task_has_failed
        guard.last_failed_paths.should =~ ['spec/javascripts/a.js.coffee']
      end
    end

  end
end
