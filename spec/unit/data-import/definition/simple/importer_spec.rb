require 'unit/spec_helper'

describe DataImport::Definition::Simple::Importer do

  let(:source) { double }
  let(:target) { double }
  let(:other_definition) { DataImport::Definition::Simple.new 'C', source, target }
  let(:definition) { DataImport::Definition::Simple.new 'A', source, target }
  let(:progress_reporter) { double('ProgressReporter') }
  let(:context) { double('Context', :name => 'A', :progress_reporter => progress_reporter) }
  before { allow(context).to receive(:definition).with('C').and_return(other_definition) }
  subject { described_class.new(context, definition) }

  describe "#run" do
    let(:reader) { double }
    let(:writer) { double }
    before { allow(definition).to receive_messages(:reader => reader) }
    before { allow(definition).to receive_messages(:writer => writer) }
    before { allow(writer).to receive(:transaction).and_yield }

    it "call #import_row for each row" do
      expect(definition.reader).to receive(:each_row).
        and_yield(:a => :b).
        and_yield(:c => :d)

      expect(subject).to receive(:import_row).with(:a => :b)
      expect(subject).to receive(:import_row).with(:c => :d)
      expect(progress_reporter).to receive(:inc).twice
      subject.run
    end

    context 'after blocks' do
      before do
        allow(definition.reader).to receive(:each_row)
      end

      it "run after the data import" do
        executed = false
        definition.after_blocks << Proc.new do
          executed = true
        end

        subject.run
        expect(executed).to eq(true)
      end

      it "have access to other definitions" do
        found_definition = nil
        definition.after_blocks << Proc.new do |context|
          found_definition = context.definition('C')
        end

        subject.run
        expect(found_definition).to eq(other_definition)
      end

      it 'have access to the definition instance' do
        found_name = nil
        definition.after_blocks << Proc.new do
          found_name = name
        end

        subject.run
        expect(found_name).to eq('A')
      end
    end

    context 'validation' do
      let(:writer) { double }
      before { definition.writer = writer }

      it 'validates data before insertion' do
        validated_rows = []
        validated_mapped_rows = []
        definition.row_validation_blocks << Proc.new do |context, row, mapped_row|
          validated_mapped_rows << mapped_row
          validated_rows << row
          true
        end

        expect(subject).to receive(:map_row).with(instance_of(DataImport::Definition::Simple::Context), {:id => 1}).and_return({:new_id => 1})
        allow(writer).to receive(:write_row)

        subject.import_row(:id => 1)
        expect(validated_mapped_rows).to eq([{:new_id => 1}])
        expect(validated_rows).to eq([{:id => 1}])
      end

      it 'doesn\'t insert an invalid row' do
        definition.row_validation_blocks << Proc.new { false }

        expect(writer).not_to receive(:write_row)

        subject.import_row(:id => 1)
      end
    end
  end

  context 'after row blocks' do
    let(:writer) { double }
    before { definition.writer = writer }
    it "run after the data import" do
      input_rows = []
      output_rows = []
      definition.after_row_blocks << Proc.new do |context, input_row, output_row|
        input_rows << input_row
        output_rows << output_row
      end

      expect(subject).to receive(:map_row).with(instance_of(DataImport::Definition::Simple::Context), {:id => 1}).and_return({:new_id => 1})
      expect(subject).to receive(:map_row).with(instance_of(DataImport::Definition::Simple::Context), {:id => 2}).and_return({:new_id => 2})
      allow(writer).to receive(:write_row)
      subject.import_row(:id => 1)
      subject.import_row(:id => 2)

      expect(input_rows).to eq([{:id => 1}, {:id => 2}])
      expect(output_rows).to eq([{:new_id => 1}, {:new_id => 2}])
    end
  end

  context do
    let(:id_mapping) { double }
    let(:name_mapping) { double }
    let(:mappings) { [id_mapping, name_mapping] }
    let(:definition) { double(:mappings => mappings,
                              :writer => writer,
                              :after_row_blocks => [],
                              :row_validation_blocks => []) }
    let(:writer) { double }


    subject { described_class.new(context, definition) }

    describe "#map_row" do
      it 'calls apply for all mappings' do
        legacy_row = {:legacy_id => 1, :legacy_name => 'hans'}
        expect(id_mapping).to receive(:apply!).with(definition, context, legacy_row, {})
        expect(name_mapping).to receive(:apply!).with(definition, context, legacy_row, {})
        expect(subject.map_row(context, legacy_row)).to eq({})
      end
    end

    describe "#import_row" do
      let(:row) { {:id => 1} }
      before { allow(subject).to receive_messages(:map_row => row) }

      it "executes the insertion" do
        expect(writer).to receive(:write_row).with({:id => 1})
        allow(definition).to receive(:row_imported)
        subject.import_row(row)
      end

      it "adds the generated id to the id mapping of the definition" do
        allow(definition.writer).to receive(:write_row).and_return(15)
        expect(definition).to receive(:row_imported).with(15, {:id => 1})
        subject.import_row(:id => 1)
      end
    end
  end

end
