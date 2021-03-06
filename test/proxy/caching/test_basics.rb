require_relative "../../test_helper"

class Test::Proxy::Caching::TestBasics < Minitest::Test
  include ApiUmbrellaTestHelpers::Setup
  include ApiUmbrellaTestHelpers::Caching
  parallelize_me!

  def setup
    super
    setup_server
  end

  def test_caches_across_different_api_keys
    user = FactoryGirl.create(:api_user)
    first = Typhoeus.get("http://127.0.0.1:9080/api/cacheable-cache-control-max-age/#{unique_test_id}?api_key=#{user.api_key}", http_options)
    assert_equal(200, first.code, first.body)

    user = FactoryGirl.create(:api_user)
    second = Typhoeus.get("http://127.0.0.1:9080/api/cacheable-cache-control-max-age/#{unique_test_id}?api_key=#{user.api_key}", http_options)
    assert_equal(200, second.code, second.body)

    assert_equal("MISS", first.headers["x-cache"])
    assert_equal("HIT", second.headers["x-cache"])
    assert_equal(first.headers["x-unique-output"], second.headers["x-unique-output"])
  end

  def test_caches_dynamic_looking_urls
    # https://docs.trafficserver.apache.org/en/latest/admin-guide/files/records.config.en.html#proxy-config-http-cache-cache-urls-that-look-dynamic
    assert_cacheable("/api/cacheable-dynamic/test.cgi?#{unique_test_id}&foo=bar&test=test&id=")
  end

  def test_separates_caches_for_identical_backend_paths_with_different_hosts
    prepend_api_backends([
      {
        :frontend_host => "127.0.0.1",
        :backend_host => "foo.example",
        :servers => [{ :host => "127.0.0.1", :port => 9444 }],
        :url_matches => [{ :frontend_prefix => "/#{unique_test_id}/cacheable-backend-host/prefix/foo/", :backend_prefix => "/cacheable-backend-host/" }],
      },
      {
        :frontend_host => "127.0.0.1",
        :backend_host => "bar.example",
        :servers => [{ :host => "127.0.0.1", :port => 9444 }],
        :url_matches => [{ :frontend_prefix => "/#{unique_test_id}/cacheable-backend-host/prefix/bar/", :backend_prefix => "/cacheable-backend-host/" }],
      },
    ]) do
      assert_cacheable("/#{unique_test_id}/cacheable-backend-host/prefix/foo/")
      assert_cacheable("/#{unique_test_id}/cacheable-backend-host/prefix/bar/")
    end
  end

  def test_separates_caches_for_identical_backend_paths_with_different_ports
    prepend_api_backends([
      {
        :frontend_host => "127.0.0.1",
        :backend_host => "foo.example",
        :servers => [{ :host => "127.0.0.1", :port => 9444 }],
        :url_matches => [{ :frontend_prefix => "/#{unique_test_id}/cacheable-backend-port/prefix/foo/", :backend_prefix => "/cacheable-backend-port/" }],
      },
      {
        :frontend_host => "127.0.0.1",
        :backend_host => "bar.example",
        :servers => [{ :host => "127.0.0.1", :port => 9441 }],
        :url_matches => [{ :frontend_prefix => "/#{unique_test_id}/cacheable-backend-port/prefix/bar/", :backend_prefix => "/cacheable-backend-port/" }],
      },
    ]) do
      assert_cacheable("/#{unique_test_id}/cacheable-backend-port/prefix/foo/")
      assert_cacheable("/#{unique_test_id}/cacheable-backend-port/prefix/bar/")
    end
  end
end
