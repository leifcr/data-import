require 'unit/spec_helper'

describe DataImport::Runner do

  let(:mock_progress_class) do
    Class.new do
      def initialize(name, total_steps); end

      def finish; end
    end
  end

  context 'with simple definitions' do
    let(:people) { DataImport::Definition.new('People', 'tblPerson', 'people') }
    let(:animals) { DataImport::Definition.new('Animals', 'tblAnimal', 'animals') }
    let(:articles) { DataImport::Definition.new('Articles', 'tblNewsMessage', 'articles') }
    let(:plan) { DataImport::ExecutionPlan.new }

    before do
      plan.add_definition(articles)
      plan.add_definition(people)
      plan.add_definition(animals)
    end

    subject { DataImport::Runner.new(plan, mock_progress_class) }

    it 'runs a set of definitions' do
      expect(articles).to receive(:run)
      expect(people).to receive(:run)
      expect(animals).to receive(:run)

      subject.run
    end

    it ":only limits the definitions, which will be run" do
      expect(people).to receive(:run)
      expect(articles).to receive(:run)

      subject.run :only => ['People', 'Articles']
    end
  end
end
