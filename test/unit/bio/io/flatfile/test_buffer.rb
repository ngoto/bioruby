#
# = test/unit/bio/io/flatfile/test_buffer.rb - unit test for Bio::FlatFile::BufferedInputStream
#
#   Copyright (C) 2006 Naohisa Goto <ng@bioruby.org>
#
# License:: The Ruby License
#
#  $Id:$
#

require 'pathname'
libpath = Pathname.new(File.join(File.dirname(__FILE__), ['..'] * 5, 'lib')).cleanpath.to_s
$:.unshift(libpath) unless $:.include?(libpath)

require 'test/unit'
require 'bio'
require 'stringio'

module Bio::TestFlatFileBufferedInputStream

  bioruby_root = Pathname.new(File.join(File.dirname(__FILE__), ['..'] * 5)).cleanpath.to_s
  TestDataPath = Pathname.new(File.join(bioruby_root, 'test', 'data')).cleanpath.to_s
  TestDataFastaFormat01 = File.join(TestDataPath, 'fasta', 'example1.txt')

  class TestBufferedInputStreamClassMethod < Test::Unit::TestCase

    def test_self_for_io
      io = File.open(TestDataFastaFormat01)
      obj = Bio::FlatFile::BufferedInputStream.for_io(io)
      assert_instance_of(Bio::FlatFile::BufferedInputStream, obj)
      assert_equal(TestDataFastaFormat01, obj.path)
    end

    def test_self_open_file
      obj = Bio::FlatFile::BufferedInputStream.open_file(TestDataFastaFormat01)
      assert_instance_of(Bio::FlatFile::BufferedInputStream, obj)
      assert_equal(TestDataFastaFormat01, obj.path)
    end

    def test_self_open_file_with_block
      obj2 = nil
      Bio::FlatFile::BufferedInputStream.open_file(TestDataFastaFormat01) do |obj|
        assert_instance_of(Bio::FlatFile::BufferedInputStream, obj)
        assert_equal(TestDataFastaFormat01, obj.path)
        obj2 = obj
      end
      assert_raise(IOError) { obj2.close }
    end
  end #class TestBufferedInputStreamClassMethod

  class TestBufferedInputStream < Test::Unit::TestCase
    def setup
      io = File.open(TestDataFastaFormat01)
      path = TestDataFastaFormat01
      @obj = Bio::FlatFile::BufferedInputStream.new(io, path)
    end

    def test_to_io
      assert_kind_of(IO, @obj.to_io)
    end

    def test_close
      assert_nil(@obj.close)
    end

    def test_rewind
      @obj.prefetch_gets
      @obj.rewind
      assert_equal('', @obj.prefetch_buffer)
    end

    def test_pos
      @obj.gets
      @obj.gets
      @obj.prefetch_gets
      assert_equal(117, @obj.pos) #the number depends on original data
    end

    def test_pos=()
      str = @obj.gets
      assert_equal(0, @obj.pos = 0)
    end
      
    def test_eof_false_first
      assert_equal(false, @obj.eof?)
    end

    def test_eof_false_after_prefetch
      while @obj.prefetch_gets; nil; end
      assert_equal(false, @obj.eof?)
    end

    def test_eof_true
      while @obj.gets; nil; end
      assert_equal(true, @obj.eof?)
    end

    def test_gets
      @obj.gets
      @obj.gets
      assert_equal("gagcaaatcgaaaaggagagatttctgcatatcaagagaaaattcgagctgagatacattccaagtgtggctactc", @obj.gets.chomp)
    end

    def test_gets_equal_prefetch_gets
      @obj.prefetch_gets
      str = @obj.prefetch_gets
      @obj.prefetch_gets
      @obj.gets
      assert_equal(@obj.gets, str)
    end

    def test_ungets
      @obj.gets
      @obj.gets
      str1 = @obj.gets
      str2 = @obj.gets
      assert_nil(@obj.ungets(str2))
      assert_nil(@obj.ungets(str1))
      assert_equal(str1, @obj.gets)
      assert_equal(str2, @obj.gets)
    end

    def test_getc
      assert_equal(?>, @obj.getc)
    end

    def test_getc_after_prefetch
      @obj.prefetch_gets
      assert_equal(?>, @obj.getc)
    end

    def test_ungetc
      c = @obj.getc
      assert_nil(@obj.ungetc(c))
      assert_equal(c, @obj.getc)
    end

    def test_ungetc_after_prefetch
      str = @obj.prefetch_gets
      c = @obj.getc
      assert_nil(@obj.ungetc(c))
      assert_equal(str, @obj.gets)
    end

    def test_prefetch_buffer
      str = @obj.prefetch_gets
      str += @obj.prefetch_gets
      assert_equal(str, @obj.prefetch_buffer)
    end

    def test_prefetch_gets
      @obj.prefetch_gets
      @obj.prefetch_gets
      @obj.gets
      str = @obj.prefetch_gets
      @obj.gets
      assert_equal(str, @obj.gets)
    end

    def test_prefetch_gets_with_arg
      # test @obj.gets
      str = @obj.prefetch_gets("\n>")
      assert_equal(str, @obj.gets("\n>"))
      # test using IO object
      io = @obj.to_io
      io.rewind
      assert_equal(str, io.gets("\n>"))
    end

    def test_skip_spaces
      @obj.gets('CDS')
      assert_nil(@obj.skip_spaces)
      assert_equal(?a, @obj.getc)
    end
                   
  end #class TestBufferedInputStream
end #module Bio::TestFlatFile

