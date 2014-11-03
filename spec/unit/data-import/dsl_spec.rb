require 'unit/spec_helper'

describe DataImport::Dsl do

  let(:plan) { double }

  context "class methods" do
    subject { DataImport::Dsl }

#     describe ".evaluate_import_config" do
#       it "executes the content of the config in a new DSL context" do
# msg = <<-RUBY
#   source 'sqlite:/'
#   target 'sqlite:/'
# RUBY
#         allow(File).to receive(msg)
#         DataImport::ExecutionPlan.should_receive(:new).and_return(plan)
#         # result = subject.evaluate_import_config('my_file')
#         # result.should == plan
#       end
#     end
  end

  context "instance methods" do
    subject { DataImport::Dsl.new(plan) }

    describe "#source" do
      it "creates a connection to the database" do
        expect(DataImport::Database).to receive(:connect).with(:options)
        subject.source :options
      end

      let(:source) { Object.new }
      it "sets the source" do
        allow(DataImport::Database).to receive(:connect).and_return(source)
        subject.source :options
        expect(subject.source_database).to eq(source)
      end

      it 'adds the before block to source database when specified' do
        my_filter = lambda {}
        allow(DataImport::Database).to receive(:connect).and_return(source)
        expect(source).to receive(:before_filter=).with(my_filter)
        plan = DataImport::Dsl.define do
          source 'sqlite:/'
          before_filter &my_filter
        end
      end
    end

    describe "#target" do
      it "creates a connection to the database" do
        expect(DataImport::Database).to receive(:connect).with(:options)
        subject.target :options
      end

      let(:target) { Object.new }
      it "sets the target" do
        allow(DataImport::Database).to receive(:connect).and_return(target)
        subject.target :options
        expect(subject.target_database).to eq(target)
      end
    end

    describe "#import" do
      it "adds a new import config to the import" do
        allow(subject).to receive(:source_database).and_return(nil)
        allow(subject).to receive(:target_database).and_return(nil)

        definition = double
        expect(DataImport::Definition::Simple).to receive(:new).with('Import 5', nil, nil).and_return(definition)
        expect(plan).to receive(:add_definition).with(definition)
        subject.import('Import 5') {}
      end

      it "sets the source and target database in the definition" do
        allow(subject).to receive(:source_database).and_return(:source)
        allow(subject).to receive(:target_database).and_return(:target)

        definition = double
        expect(DataImport::Definition::Simple).to receive(:new).with('a', :source, :target).and_return(definition)
        expect(plan).to receive(:add_definition).with(definition)

        subject.import('a') {}
      end

      # it "executes the block in an import context" do
      #   allow(subject).to receive(:source_database).and_return(nil)
      #   allow(subject).to receive(:target_database).and_return(nil)

      #   my_block = lambda {}
      #   import_dsl = double
      #   definition = double
      #   DataImport::Definition::Simple.should_receive(:new).with(any_args).and_return(definition)
      #   plan.should_receive(:add_definition).with(definition)
      #   DataImport::Dsl::Import.should_receive(:new).with(definition).and_return(import_dsl)

      #   # import_dsl.should_receive(:instance_eval).with(&my_block)
      #   # subject.import 'name', &my_block
      # end
    end

    describe "#script" do
      let(:definition) { double }

      it "adds a new script config to the import" do
        allow(subject).to receive(:source_database).and_return(nil)
        allow(subject).to receive(:target_database).and_return(nil)

        expect(DataImport::Definition::Script).to receive(:new).with('Script', nil, nil).and_return(definition)
        expect(plan).to receive(:add_definition).with(definition)
        subject.script('Script') {}
      end

      it "sets the source and target database in the definition" do
        allow(subject).to receive(:source_database).and_return(:source)
        allow(subject).to receive(:target_database).and_return(:target)

        expect(DataImport::Definition::Script).to receive(:new).with('a', :source, :target).and_return(definition)
        expect(plan).to receive(:add_definition).with(definition)

        subject.script('a') {}
      end

      # it "executes the block in an script conext" do
      #   allow(subject).to receive(:source_database).and_return(nil)
      #   allow(subject).to receive(:target_database).and_return(nil)

      #   my_block = lambda {}
      #   script_dsl = double
      #   DataImport::Definition::Script.should_receive(:new).with(any_args).and_return(definition)
      #   plan.should_receive(:add_definition).with(definition)
      #   DataImport::Dsl::Script.should_receive(:new).with(definition).and_return(script_dsl)

      #   # script_dsl.should_receive(:instance_eval).with(&my_block)
      #   # subject.script 'name', &my_block
      # end
    end
  end
end
