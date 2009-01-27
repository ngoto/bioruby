#
# = bio/io/togows.rb - REST interface for TogoWS
#
# Copyright::  Copyright (C) 2009 Naohisa Goto <ng@bioruby.org>
# License::    The Ruby License
#
# $Id:$
#
# Bio::TogoWS is a set of clients for the TogoWS web services
# (http://togows.dbcls.jp/).
#
# * Bio::TogoWS::REST is a REST client for the TogoWS.
# * Bio::TogoWS::SOAP will be implemented in the future.
#

require 'uri'
require 'cgi'
require 'bio/command'

module Bio

  # Bio::TogoWS is a namespace for the TogoWS web services.
  module TogoWS


    # == Description
    #
    # Bio::TogoWS::REST is a REST client for the TogoWS web service.
    #
    # Details of the service are desribed in the following URI.
    #
    # * http://togows.dbcls.jp/site/en/rest.html
    #
    # == Examples
    # 
    # For light users, class methods can be used.
    #
    #   print Bio::TogoWS::REST.entry('genbank', 'AF237819')
    #   print Bio::TogoWS::REST.search('uniprot', 'lung cancer')
    #
    # For heavy users, an instance of the REST class can be created, and
    # using the instance is more efficient than using class methods.
    #
    #   t = Bio::TogoWS::REST.new
    #   print t.entry('genbank', 'AF237819')
    #   print t.search('uniprot', 'lung cancer')
    #
    # == References
    #
    # * http://togows.dbcls.jp/site/en/rest.html
    #
    class REST

      # URI of the TogoWS REST service
      BASE_URI = 'http://togows.dbcls.jp/'.freeze

      # preset default databases used by the retrieve method
      DEFAULT_RETRIEVAL_DATABASES =
        %w( genbank uniprot embl ddbj dad gene
            pdb enzyme compound drug glycan reaction orthology pubmed )

      # Creates a new object.
      # ---
      # *Arguments*:
      # * (optional) _uri_: String or URI object
      # *Returns*:: new object
      def initialize(uri = BASE_URI)
        uri = URI.parse(uri) unless uri.kind_of?(URI)
        @pathbase = uri.path
        @pathbase = '/' + @pathbase unless /\A\// =~ @pathbase
        @pathbase = @pathbase + '/' unless /\/\z/ =~ @pathbase
        @http = Bio::Command.new_http(uri.host, uri.port)
        @header = {
          'User-Agent' => "BioRuby/#{Bio::BIORUBY_VERSION.join('.')}"
        }
        @debug = false
      end

      # If true, shows debug information to $stderr.
      attr_accessor :debug

      # Intelligent version of the entry method.
      # If two or more databases are specified, sequentially tries
      # them until valid entry is obtained.
      #
      # If database is not specified, preset default databases are used. 
      #
      # When multiple IDs and multiple databases are specified, sequentially
      # tries each IDs. Note that results with no hits found or with server
      # errors are regarded as void strings. Also note that data format of
      # the result entries can be different from entries to entries.
      # 
      # ---
      # *Arguments*:
      # * (required) _ids_: (String) an entry ID, or
      #   (Array containing String) IDs. Note that strings containing ","
      # * (optional) _hash_: (Hash) options below can be passed as a hash.
      #   * (optional) <I>:database</I>: (String) database name, or
      #     (Array containing String) database names.
      #   * (optional) <I>:format</I>: (String) format
      #   * (optional) <I>:field</I>: (String) gets only the specified field
      # *Returns*:: String or nil
      def retrieve(ids, hash = {})
        begin
          a = ids.to_ary
        rescue NoMethodError
          ids = ids.to_s
        end
        ids = a.join(',') if a
        ids = ids.split(',')

        dbs = hash[:database] || DEFAULT_RETRIEVAL_DATABASES
        return nil if dbs.empty? or ids.empty?

        if dbs.size == 1 then
          return entry(dbs[0], ids, hash[:format], hash[:field])
        end

        results = []
        ids.each do |idstr|
          dbs.each do |dbstr|
            r = entry(dbstr, idstr, hash[:format], hash[:field])
            if r and !r.strip.empty? then
              results.push r
              break
            end
          end #dbs.each
        end #ids.each
        
        results.join('')
      end #def retrieve

      # Retrieves entries corresponding to the specified IDs.
      #
      # Example:
      #   t = Bio::TogoWS::REST.new
      #   kuma = t.entry('genbank', 'AF237819')
      #   # multiple IDs at a time
      #   misc = t.entry('genbank', [ 'AF237819', 'AF237820' ])
      #   # with format change
      #   p53 = t.entry('uniprot', 'P53_HUMAN', 'fasta')
      #
      # ---
      # *Arguments*:
      # * (required) _database_: (String) database name
      # * (required) _ids_: (String) an entry ID, or
      #   (Array containing String) IDs. Note that strings containing ","
      #   are regarded as multiple IDs.
      # * (optional) _format_: (String) format. nil means the default format
      #   (differs depending on the database).
      # * (optional) _field_: (String) gets only the specified field if not nil
      # *Returns*:: String or nil
      def entry(database, ids, format = nil, field = nil)
        begin
          a = ids.to_ary
        rescue NoMethodError
          ids = ids.to_s
        end
        ids = a.join(',') if a

        arg = [ 'entry', database, ids ]
        arg.push field if field
        arg[-1] = "#{arg[-1]}.#{format}" if format
        response = get(*arg)

        prepare_return_value(response)
      end

      # Database search.
      # Format of the search term string follows the Common Query Language.
      # * http://en.wikipedia.org/wiki/Common_Query_Language
      #
      # Example:
      #   t = Bio::TogoWS::REST.new
      #   print t.search('uniprot', 'lung cancer')
      #   # only get the 10th and 11th hit ID
      #   print t.search('uniprot', 'lung cancer', 10, 2)
      #   # with json format
      #   print t.search('uniprot', 'lung cancer', 10, 2, 'json')
      #
      # ---
      # *Arguments*:
      # * (required) _database_: (String) database name
      # * (required) _query_: (String) query string
      # * (optional) _offset_: (Integer) offset in search results.
      # * (optional) _limit_: (Integer) max. number of returned results.
      #   If offset is not nil and the limit is nil, it is set to 1.
      # * (optional) _format_: (String) format. nil means the default format.
      # *Returns*:: String or nil
      def search(database, query, offset = nil, limit = nil, format = nil)
        arg = [ 'search', database, query ]
        if offset then
          limit ||= 1
          arg.push "#{offset},#{limit}"
        end
        arg[-1] = "#{arg[-1]}.#{format}" if format
        response = get(*arg)

        prepare_return_value(response)
      end

      # Data format conversion.
      #
      # Example:
      #   t = Bio::TogoWS::REST.new
      #   blast_string = File.read('test.blastn')
      #   t.convert(blast_string, 'blast', 'gff')
      #
      # ---
      # *Arguments*:
      # * (required) _text_: (String) input data
      # * (required) _inputformat_: (String) data source format
      # * (required) _format_: (String) output format
      # *Returns*:: String or nil
      def convert(data, inputformat, format)
        response = post_data(data, 'convert', "#{inputformat}.#{format}")

        prepare_return_value(response)
      end

      # Returns list of available databases in the entry service.
      # ---
      # *Returns*:: Array containing String
      def entry_database_list
        database_list('entry')
      end

      # Returns list of available databases in the search service.
      # ---
      # *Returns*:: Array containing String
      def search_database_list
        database_list('search')
      end

      #--
      # class methods
      #++

      # The same as Bio::TogoWS::REST#entry.
      def self.entry(*arg)
        self.new.entry(*arg)
      end

      # The same as Bio::TogoWS::REST#search.
      def self.search(*arg)
        self.new.search(*arg)
      end

      # The same as Bio::TogoWS::REST#convert.
      def self.convert(*arg)
        self.new.convert(*arg)
      end

      # The same as Bio::TogoWS::REST#retrieve.
      def self.retrieve(*arg)
        self.new.retrieve(*arg)
      end

      # The same as Bio::TogoWS::REST#entry_database_list
      def self.entry_database_list(*arg)
        self.new.entry_database_list(*arg)
      end

      # The same as Bio::TogoWS::REST#search_database_list
      def self.search_database_list(*arg)
        self.new.search_database_list(*arg)
      end

      private

      # Access to the TogoWS by using GET method.
      #
      # Example 1:
      #   get('entry', 'genbank', AF209156')
      # Example 2:
      #   get('search', 'uniprot', 'lung cancer')
      #
      # ---
      # *Arguments*:
      # * (optional) _path_: String
      # *Returns*:: Net::HTTPResponse object
      def get(*paths)
        path = make_path(paths)
        if @debug then
          $stderr.puts "TogoWS: HTTP#get(#{path.inspect}, #{@header.inspect})"
        end
        @http.get(path, @header)
      end

      # Access to the TogoWS by using GET method. 
      # Always adds '/' at the end of the path.
      #
      # Example 1:
      #   get_dir('entry')
      #
      # ---
      # *Arguments*:
      # * (optional) _path_: String
      # *Returns*:: Net::HTTPResponse object
      def get_dir(*paths)
        path = make_path(paths)
        path += '/' unless /\/\z/ =~ path
        if @debug then
          $stderr.puts "TogoWS: HTTP#get(#{path.inspect}, #{@header.inspect})"
        end
        @http.get(path, @header)
      end

      # Access to the TogoWS by using POST method.
      # The data is stored to the form key 'data'.
      # Mime type is 'application/x-www-form-urlencoded'.
      # ---
      # *Arguments*:
      # * (required) _data_: String
      # * (optional) _path_: String
      # *Returns*:: Net::HTTPResponse object
      def post_data(data, *paths)
        path = make_path(paths)
        if @debug then
          $stderr.puts "TogoWS: Bio::Command.http_post_form(#{path.inspect}, { \"data\" => (#{data.size} bytes) }, #{@header.inspect})"
        end
        Bio::Command.http_post_form(@http, path, { 'data' => data }, @header)
      end

      # Generates path string from the given paths.
      # ---
      # *Arguments*:
      # * (required) _paths_: Array containing String objects
      # *Returns*:: String
      def make_path(paths)
        @pathbase + paths.collect { |x| CGI.escape(x.to_s) }.join('/')
      end

      # If response.code == "200", returns body as a String.
      # Otherwise, returns nil.
      def prepare_return_value(response)
        if @debug then
          $stderr.puts "TogoWS: #{response.inspect}"
        end
        if response.code == "200" then
          response.body
        else
          nil
        end
      end

      # Returns list of available databases
      # ---
      # *Arguments*:
      # * (required) _service_: String
      # *Returns*:: Array containing String
      def database_list(service)
        response = get_dir(service)
        str = prepare_return_value(response)
        if str then
          str.chomp.split(/\r?\n/)
        else
          raise 'Unexpected server response'
        end
      end

    end #class REST

  end #module TogoWS

end #module Bio
