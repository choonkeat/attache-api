require 'test_helper'

class Attache::API::TestUtils < Minitest::Test
  def test_array_on_array
    assert_equal [{ key: :value }], Attache::API::Utils.array([{ key: :value }])
  end

  def test_array_on_hash
    assert_equal [{ key: :value }], Attache::API::Utils.array({ key: :value })
  end

  def test_array_on_string
    assert_equal ["string"], Attache::API::Utils.array("string")
  end

  def test_array_on_blank
    assert_equal [], Attache::API::Utils.array("")
  end

  def test_array_on_nil
    assert_equal [], Attache::API::Utils.array(nil)
  end

  def test_array_on_blank_in_array
    assert_equal ["string"], Attache::API::Utils.array(["", "string", nil])
  end
end
