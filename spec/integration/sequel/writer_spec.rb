require 'integration/spec_helper'

describe DataImport::Sequel::Writer do
  let(:table_name) { 'cities' }
  let(:connection) { DataImport::Database.connect('sqlite:/') }

  before do
    connection.create_table :cities do
      primary_key :id
      String :name
    end
  end

  describe DataImport::Sequel::InsertWriter do
    subject { DataImport::Sequel::InsertWriter.new(connection, table_name) }

    it 'writes a row to the specified table' do
      expect(subject.write_row(:id => 2, :name => 'Switzerland')).to eq(2)
      expect(connection[:cities].to_a).to eq([{:id => 2, :name => "Switzerland"}])
    end

    it 'works with transactions' do
      subject.transaction do
        expect(subject.write_row(:id => 2, :name => 'Switzerland')).to eq(2)
      end
      expect(connection[:cities].to_a.size).to eq(1)
    end
  end

  describe DataImport::Sequel::UpdateWriter do
    subject { DataImport::Sequel::UpdateWriter.new(connection, table_name) }

    before do
      connection[:cities].insert(:id => 5, :name => 'Schweiz')
    end

    it 'writes a row to the specified table' do
      expect(subject.write_row(:id => 5, :name => 'Switzerland')).to eq(5)
      expect(connection[:cities].to_a).to eq([{:id => 5, :name => "Switzerland"}])
    end

    it 'works with transactions' do
      subject.transaction do
        expect(subject.write_row(:id => 5, :name => 'Switzerland')).to eq(5)
      end
      expect(connection[:cities].to_a.size).to eq(1)
    end


    it 'raises an error when no :id was in the row' do
      expect do
        subject.write_row(:name => 'this will not work')
      end.to raise_error(DataImport::MissingIdError)
    end
  end

  describe DataImport::Sequel::UniqueWriter do
    subject { DataImport::Sequel::UniqueWriter.new(connection, table_name, :columns => [:name]) }

    it 'writes a row to the specified table' do
      expect(subject.write_row(:id => 3, :name => 'Italy')).to eq(3)
      expect(connection[:cities].to_a).to eq([{:id => 3, :name => 'Italy'}])
    end

    it 'works with transactions' do
      subject.transaction do
        expect(subject.write_row(:id => 3, :name => 'Italy')).to eq(3)
      end
      expect(connection[:cities].to_a.size).to eq(1)
    end

    it 'doesn\'t write a record if a similar record exists' do
      connection[:cities].insert(:id => 6, :name => 'Spain')

      expect(subject.write_row(:id => 2, :name => 'Spain')).to eq(6)
      expect(connection[:cities].to_a.size).to eq(1)
    end
  end

end
