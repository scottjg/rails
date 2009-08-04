require 'abstract_unit'
require 'mocha'

class DigestTest < Test::Unit::TestCase
  DEFAULT_WWW_AUTHENTICATE_HEADER = %(Digest realm="AdGear API", qop="auth", algorithm=MD5, nonce="MTI0OTQxNzM2NDo5ZjM3MzhmMzhlZTM4ODNlZmFjM2FhNjNjMTgxZmIxNQ==", opaque="a21e6002d2bd70e6dbeaca094ded4f93")

  def test_returns_opaque_unchanged
    value = ActiveResource::Digest.authenticate("http://site.com/api/people", "user", "pass", DEFAULT_WWW_AUTHENTICATE_HEADER)
    assert_match /opaque="a21e6002d2bd70e6dbeaca094ded4f93"/, value
  end

  def test_returns_nonce_unchanged
    value = ActiveResource::Digest.authenticate("http://site.com/api/people", "user", "pass", DEFAULT_WWW_AUTHENTICATE_HEADER)
    assert_match /nonce="MTI0OTQxNzM2NDo5ZjM3MzhmMzhlZTM4ODNlZmFjM2FhNjNjMTgxZmIxNQ=="/, value
  end

  def test_returns_path_of_uri
    value = ActiveResource::Digest.authenticate("http://site.com/api/people", "user", "pass", DEFAULT_WWW_AUTHENTICATE_HEADER)
    assert_match /uri="\/api\/people"/, value
  end

  def test_returns_realm_unchanged
    value = ActiveResource::Digest.authenticate("http://site.com/api/people", "user", "pass", DEFAULT_WWW_AUTHENTICATE_HEADER)
    assert_match /realm="AdGear API"/, value
  end

  def test_uses_request_method_to_calculate_digest
    value = ActiveResource::Digest.authenticate("http://site.com/api/people", "user", "pass", DEFAULT_WWW_AUTHENTICATE_HEADER, :get)
    assert_match /response="6830a9204e6b7c611879db0076587bdb"/, value, "Did the implementation use the request method to calculate the digest?"
  end

  def test_uses_request_method_to_calculate_digest
    value = ActiveResource::Digest.authenticate("http://site.com/api/people", "user", "pass", DEFAULT_WWW_AUTHENTICATE_HEADER, :post)
    assert_match /response="2c745576ed636753b68311db8ab12f5b"/, value, "Did the implementation use the request method to calculate the digest?"
  end
end
