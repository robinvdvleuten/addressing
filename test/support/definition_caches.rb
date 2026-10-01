# frozen_string_literal: true

class Minitest::Test
  # Drops the subdivision definitions that are cached per process, so that
  # the next lookup reads the data files again.
  def reset_definition_caches
    Addressing::Subdivision.instance_variable_set(:@definitions, nil)
    Addressing::Subdivision.instance_variable_set(:@parents, nil)
  end
end
