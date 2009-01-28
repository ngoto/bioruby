#
# test/unit/bio/io/test_togows.rb - Unit test for Bio::TogoWS
#
# Copyright::   Copyright (C) 2009
#               Naohisa Goto <ng@bioruby.org>
# License::     The Ruby License
#
#  $Id:$
#

require 'pathname'
libpath = Pathname.new(File.join(File.dirname(__FILE__), ['..'] * 4, 'lib')).cleanpath.to_s
$:.unshift(libpath) unless $:.include?(libpath)

require 'uri'
require 'net/http'
require 'bio/version'
require 'bio/io/togows'
require 'test/unit'

module Bio

  # unit test for Bio::TogoWS::REST
  class TestTogoWSREST < Test::Unit::TestCase

    def setup
      @togows = Bio::TogoWS::REST.new
    end

    def test_debug_default
      assert_equal(false, @togows.debug)
    end

    def test_debug
      assert_equal(true, @togows.debug = true)
      assert_equal(true, @togows.debug)
      assert_equal(false, @togows.debug = false)
      assert_equal(false, @togows.debug)
      assert_equal(true, @togows.debug = true)
      assert_equal(true, @togows.debug)
    end

    def test_internal_http
      assert_kind_of(Net::HTTP, @togows.internal_http)
    end

  end #class TestTogoWSREST

  # unit test for Bio::TogoWS::REST class methods
  class TestTogoWSRESTclassMethod < Test::Unit::TestCase

    def test_new
      assert_instance_of(Bio::TogoWS::REST, Bio::TogoWS::REST.new)
    end

    def test_new_with_uri_string
      t = Bio::TogoWS::REST.new('http://localhost:1234/test')
      assert_instance_of(Bio::TogoWS::REST, t)
      http = t.internal_http
      assert_equal('localhost', http.address)
      assert_equal(1234, http.port)
      assert_equal('/test/', t.instance_eval { @pathbase })
    end

    def test_new_with_uri_object
      u = URI.parse('http://localhost:1234/test')
      t = Bio::TogoWS::REST.new(u)
      assert_instance_of(Bio::TogoWS::REST, t)
      http = t.internal_http
      assert_equal('localhost', http.address)
      assert_equal(1234, http.port)
      assert_equal('/test/', t.instance_eval { @pathbase })
    end

    def test_entry
      assert_respond_to(Bio::TogoWS::REST, :entry)
    end

    def test_search
      assert_respond_to(Bio::TogoWS::REST, :search)
    end

    def test_convert
      assert_respond_to(Bio::TogoWS::REST, :convert)
    end

    def test_retrieve
      assert_respond_to(Bio::TogoWS::REST, :retrieve)
    end

  end #class TestTogoWSRESTclassMethod

end #module Bio
