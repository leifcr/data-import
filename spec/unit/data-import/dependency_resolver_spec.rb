require 'unit/spec_helper'

describe DataImport::DependencyResolver do

  let(:strategy_class) { double }
  let(:strategy) { double }
  let(:a) { double('A', :name => 'A', :dependencies => []) }
  let(:b) { double('B', :name => 'B', :dependencies => ['A']) }
  let(:c) { double('C', :name => 'C', :dependencies => ['A', 'B']) }
  let(:plan) { DataImport::ExecutionPlan.new([a, b, c]) }
  subject { DataImport::DependencyResolver.new(plan, strategy) }

  let(:graph) {
    graph = {
      'A' => [],
      'B' => ['A'],
      'C' => ['A', 'B']
    }
  }

  before do
    allow(strategy).to receive_messages(:call => ['A', 'B'])
    expect(strategy).to receive(:new).with(graph).and_return(strategy)
  end

  it 'should return an ExecutionPlan' do
    # Create the input plan before the mocks are setup
    plan

    resolved_plan = double
    expect(DataImport::ExecutionPlan).to receive(:new).with([a, b]).and_return(resolved_plan)
    expect(subject.resolve).to eq(resolved_plan)
  end

  it 'passes the options to the resolving strategy' do
    options = {:run_only => ['A', 'B']}
    expect(strategy).to receive(:call).with(options)

    subject.resolve(options)
  end

end

describe DataImport::DependencyResolver, 'algorythm' do

  subject { DataImport::DependencyResolver::LoopStrategy.new(graph) }

  context 'without dependencies' do
    let(:graph) {
      { 'A' => [],
        'B' => [],
        'C' => []
      }
    }

    it 'can limit the definitions which should run' do
      expect(subject.call(:run_only => ['A', 'C'])).to eq(['A', 'C'])
    end
  end

  context 'with nested dependencies' do
    let(:graph) {
      { 'A' => [],
        'B' => [],
        'A1' => ['A'],
        'A-B-1' => ['A', 'B'],
        'AB-A1-1' => ['A-B-1', 'A1']
      }
    }

    it 'executes leaf-definitions first and works to the top' do
      expect(subject.call).to eq(['A', 'B', 'A1', 'A-B-1', 'AB-A1-1'])
    end

    it 'runs only necessary definitions when :run_only is passed' do
      expect(subject.call(:run_only => ['A1', 'B'])).to eq(['A', 'B', 'A1'])
    end
  end

  context 'with growing dependencies' do
    let(:graph) {
      { 'A' => [],
        'B' => [],
        'A1' => ['A', 'B'],
        'A11' => ['A1']
      }
    }

    it 'runs only necessary definitions when :run_only is passed' do
      expect(subject.call(:run_only => ['A11'])).to eq(['A', 'B', 'A1', 'A11'])
    end
  end

  context 'with circular dependencies' do
    let(:graph) {
      { 'A' => ['B'],
        'B' => ['A']
      }
    }

    it "can't resolve them and raises an exception" do
      expect do
        subject.call
      end.to raise_error(DataImport::CircularDependencyError)
    end
  end

  context 'with non-exisitng dependencies' do
    let(:graph) {
      { 'A' => ['NOT_PRESENT'] }
    }

    it 'raises an error' do
      expect do
        subject.call
      end.to raise_error(DataImport::MissingDefinitionError)
    end

  end

  context 'with dependencies that appear to be circular but are not' do
    let(:graph) {
      { 'A' => [],
        'AB' => ['A'],
        'AB-A' => ['AB', 'A']
      }
    }

    it 'resolves them' do
      subject.call == ['A', 'AB', 'AB-A']
    end
  end
end
