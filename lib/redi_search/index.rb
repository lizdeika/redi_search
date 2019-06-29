# frozen_string_literal: true

require "redi_search/add"
require "redi_search/create"
require "redi_search/schema"
require "redi_search/search"
require "redi_search/spellcheck"
require "redi_search/alter"

module RediSearch
  class Index
    attr_reader :name, :schema, :model

    def initialize(name, schema, model = nil)
      @name = name
      @schema = Schema.new(schema)
      @model = model
    end

    def search(term = nil, **term_options)
      Search.new(self, term, **term_options)
    end

    def spellcheck(query, distance: 1)
      Spellcheck.new(self, query, distance: distance)
    end

    def create(**options)
      Create.new(self, schema, options).call
    end

    def create!(**options)
      Create.new(self, schema, options).call!
    end

    def drop
      drop!
    rescue Redis::CommandError
      false
    end

    def drop!
      client.call!("DROP", name).ok?
    end

    def add(document, score: 1.0, **options)
      Add.new(self, document, score: score, **options).call
    end

    def add!(document, score: 1.0, **options)
      Add.new(self, document, score: score, **options).call!
    end

    def add_multiple!(documents)
      client.pipelined do
        documents.each do |document|
          add!(document)
        end
      end.ok?
    end

    def del(document, delete_document: false)
      client.call!("DEL", name, document.document_id, ("DD" if delete_document))
    end

    def exist?
      !client.call!("INFO", name).empty?
    rescue Redis::CommandError
      false
    end

    def info
      hash = Hash[*client.call!("INFO", name)]
      info_struct = Struct.new(*hash.keys.map(&:to_sym))
      info_struct.new(*hash.values)
    rescue Redis::CommandError
      nil
    end

    def fields
      schema.fields.map(&:to_s)
    end

    def reindex(docs)
      drop if exist?
      create
      add_multiple! docs
    end

    def document_count
      info["num_docs"].to_i
    end

    def alter(field_name, schema)
      Alter.new(self, field_name, schema).call!
    end

    private

    def client
      RediSearch.client
    end
  end
end
