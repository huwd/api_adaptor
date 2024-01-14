# frozen_string_literal: true

RSpec.describe "Version: #{ApiAdaptor::VERSION}" do
  it { expect { described_class }.not_to raise_error }
end
