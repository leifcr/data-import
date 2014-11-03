require 'unit/spec_helper'

describe DataImport::ExecutionPlan do

  let(:people) { double(:name => 'People') }
  let(:houses) { double(:name => 'House') }
  let(:definitions) { [people, houses] }

  it 'can be created with a set of definitions' do
    plan = DataImport::ExecutionPlan.new(definitions)
    expect(plan.definitions).to eq(definitions)
  end

  it 'raises an error when a non-existing definition is fetched' do
    expect do
      subject.definition('I-do-not-exist')
    end.to raise_error(DataImport::MissingDefinitionError)
  end

  it 'definitions can be added' do
    subject.add_definition(people)
    subject.add_definition(houses)
    expect(subject.definitions).to eq([people, houses])
  end

  context 'plan with definitions' do
    subject { DataImport::ExecutionPlan.new(definitions) }

    it 'stores the order the definitions were added' do
      cats = double(:name => 'Cats')
      dogs = double(:name => 'Dogs')
      subject.add_definition(cats)
      subject.add_definition(dogs)

      expect(subject.definitions).to eq([people, houses, cats, dogs])
    end

    it 'definitions can be fetched by name' do
      expect(subject.definition('People')).to eq(people)
    end
  end

end
