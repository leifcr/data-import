require 'unit/spec_helper'

describe DataImport::Logger do
  let(:important) { double }
  let(:full) { double }
  subject { described_class.new(full, important) }

  it 'writes debug and info messages only to the full logger' do
    expect(full).to receive(:debug).with('debug message')
    expect(full).to receive(:info).with('info message')

    subject.debug 'debug message'
    subject.info 'info message'
  end

  it 'writes warn, error and fatal messages to both loggers' do
    expect(full).to receive(:warn).with('warn message')
    expect(full).to receive(:error).with('error message')
    expect(full).to receive(:fatal).with('fatal message')
    expect(important).to receive(:warn).with('warn message')
    expect(important).to receive(:error).with('error message')
    expect(important).to receive(:fatal).with('fatal message')

    subject.warn 'warn message'
    subject.error 'error message'
    subject.fatal 'fatal message'
  end
end
