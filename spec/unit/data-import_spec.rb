require 'unit/spec_helper'

describe DataImport do

  subject { DataImport }

  describe ".run_definitions!" do
    let(:runner) { double }
    let(:plan) { DataImport::ExecutionPlan.new(definitions) }
    let(:definitions) { [double(:name => 'Artists'), double(:name => 'Paints')] }

    it "can execute a configuration file" do
      expect(DataImport::Dsl).to receive(:evaluate_import_config).with('my_file').and_return(plan)
      expect(DataImport::Runner).to receive(:new).with(plan).and_return(runner)
      expect(runner).to receive(:run).with(:only => ['C'])

      subject.run_config! 'my_file', :only => ['C']
    end

    it "uses the DataImport::Runner to execute the plan" do
      expect(DataImport::Runner).to receive(:new).with(plan).and_return(runner)
      expect(runner).to receive(:run)

      subject.run_plan!(plan)
    end

    it "passes options to the runner" do
      expect(DataImport::Runner).to receive(:new).with(plan).and_return(runner)
      expect(runner).to receive(:run).with(:only => ['A', 'B'])

      subject.run_plan!(plan, :only => ['A', 'B'])
    end
  end
end
