require 'unit/spec_helper'

describe DataImport::Definition do

  subject { DataImport::Definition.new('a', :source, :target) }

  it 'executes in 1 step' do
    expect(subject.total_steps_required).to eq(1)
  end

  describe "#dependencies" do
    it "can have dependent definitions which must run before" do
      subject.add_dependency 'b'
      subject.add_dependency 'c'
      expect(subject.dependencies).to eq(['b', 'c'])
    end
  end
end
