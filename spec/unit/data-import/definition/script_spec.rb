require 'unit/spec_helper'

describe DataImport::Definition::Script do
  let(:source) { double }
  let(:target) { double }
  subject { described_class.new('a', source, target) }

  describe '#run' do
    let(:context) { double(:name => 'ABC') }

    it 'execute the definition and displays the progress' do
      found_name = nil
      subject.body = Proc.new { found_name = name }

      expect(target).to receive(:transaction).and_yield

      subject.run(context)
      expect(found_name).to eq('ABC')
    end
  end
end
