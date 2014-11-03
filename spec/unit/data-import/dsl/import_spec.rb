require 'unit/spec_helper'

describe DataImport::Dsl::Import do

  let(:source) { double(:adapter_scheme => 'sqlite') }
  let(:target) { double }

  let(:definition) { DataImport::Definition::Simple.new('d', source, target) }
  subject { DataImport::Dsl::Import.new(definition) }

  describe "#from" do
    context 'when a table-name is passed' do
      it "assigns the source dataset to the definition" do
        reader = double
        expect(DataImport::Sequel::Table).to receive(:new).
          with(source, 'tblConversions', :primary_key => 'sID').
          and_return(reader)

        subject.from 'tblConversions', :primary_key => 'sID'
        expect(definition.reader).to eq(reader)
      end
    end

    context 'when a block is passed' do
      it 'uses the block to build the base query' do
        custom_dataset = lambda { |db| }

        reader = double
        expect(DataImport::Sequel::Dataset).to receive(:new).with(source, custom_dataset).and_return(reader)

        subject.from &custom_dataset
        expect(definition.reader).to eq(reader)
      end
    end
  end

  describe "#to" do
    let(:writer) { double('writer') }

    it "assigns a table-writer for the given table to the definition" do
      allow(target).to receive(:adapter_scheme)
      expect(DataImport::Sequel::InsertWriter).to receive(:new).with(target, 'tblChickens').and_return(writer)
      subject.to 'tblChickens'
      expect(definition.writer).to eq(writer)
    end

    it 'uses an UpdateWriter when the :mode is set to :update' do
      allow(target).to receive(:adapter_scheme)
      expect(DataImport::Sequel::UpdateWriter).to receive(:new).with(target, 'tblFoxes').and_return(writer)
      subject.to 'tblFoxes', :mode => :update
      expect(definition.writer).to eq(writer)
    end

    it 'extends the writer with the UpdateSequence module if the database is postgres' do
      allow(target).to receive_messages(:adapter_scheme => :postgres)
      allow(DataImport::Sequel::InsertWriter).to receive_messages(:new => writer)

      subject.to 'tblChickens'
      expect(writer).to be_kind_of(DataImport::Sequel::Postgres::UpdateSequence)
    end

    it 'uses a UniqueWriter when the :mode is set to :unique' do
      allow(target).to receive(:adapter_scheme)
      expect(DataImport::Sequel::UniqueWriter).to receive(:new).with(target, 'tblAdresses', :columns => [:name, :gender]).and_return(writer)

      subject.to 'tblAdresses', :mode => [:unique, :columns => [:name, :gender]]
      expect(definition.writer).to eq(writer)
    end
  end

  describe "#dependencies" do
    it "sets the list of definitions it depends on" do
      subject.dependencies 'a', 'b'
      expect(definition.dependencies).to eq(['a', 'b'])
    end

    it "can be called multiple times" do
      subject.dependencies 'a', 'b'
      subject.dependencies 'x'
      subject.dependencies 'y'
      expect(definition.dependencies).to eq(['a', 'b', 'x', 'y'])
    end
  end

  describe 'mapping definitions' do
    describe "#mapping" do
      it "adds a column mapping to the definition" do
        name_mapping = double
        expect(DataImport::Definition::Simple::NameMapping).to receive(:new).with(:a, :b).and_return(name_mapping)
        expect(definition).to receive(:add_mapping).with(name_mapping)

        subject.mapping :a => :b
      end

      context 'legacy block mappings' do
        let(:block) { lambda{|value|} }
        it "adds a proc to the mappings" do
          block_mapping = double
          expect(DataImport::Definition::Simple::BlockMapping).to receive(:new).with([:a], block).and_return(block_mapping)
          expect(definition).to receive(:add_mapping).with(block_mapping)

          subject.mapping :a, &block
        end

        it "adds a proc with multiple fields to the mappings" do
          block_mapping = double
          expect(DataImport::Definition::Simple::BlockMapping).to receive(:new).with([:a, :b], block).and_return(block_mapping)
          expect(definition).to receive(:add_mapping).with(block_mapping)

          subject.mapping :a, :b, &block
        end

        it 'adds a proc with all fields to the mappings' do
          block_mapping = double
          expect(DataImport::Definition::Simple::BlockMapping).to receive(:new).with([:*], block).and_return(block_mapping)

          expect(definition).to receive(:add_mapping).with(block_mapping)

          subject.mapping :*, &block
        end
      end

      context 'wildcard block mappings' do
        let(:block) { lambda {} }
        it 'adds a proc with all fields to the mappings' do
          block_mapping = double
          expect(DataImport::Definition::Simple::WildcardBlockMapping).to receive(:new).with(block).and_return(block_mapping)

          expect(definition).to receive(:add_mapping).with(block_mapping)

          subject.mapping 'my complex mapping', &block
        end
      end
    end

    describe "#seed" do
      it 'adds a SeedMapping to the definition' do
        seed_hash = {:message => 'welcome', :source => 'migrated'}
        seed_mapping = double
        expect(DataImport::Definition::Simple::SeedMapping).to receive(:new).with(seed_hash).and_return(seed_mapping)
        expect(definition).to receive(:add_mapping).with(seed_mapping)

        subject.seed seed_hash
      end
    end
  end

  describe "#after" do
    let(:block) { lambda{} }
    it "adds a proc to be executed after the import" do
      subject.after &block
      expect(definition.after_blocks).to include(block)
    end
  end

  it "#after_row adds a block, which is executed after every row" do
    my_block = lambda {}
    subject.after_row &my_block
    definition.after_row_blocks == [my_block]
  end

  it '#validate_row adds a validation block' do
    validation_block = lambda {}
    subject.validate_row &validation_block
    expect(definition.row_validation_blocks).to eq([validation_block])
  end

end
