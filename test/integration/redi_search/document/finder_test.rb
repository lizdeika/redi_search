# frozen_string_literal: true

require "test_helper"
require "redi_search/document"

module RediSearch
  class Document
    class FinderTest < Minitest::Test
      def setup
        @index = Index.new(:users, first: :text, last: :text)
        @index.create
        @index.add(Document.for_object(@index, users(index: 0)))
        @index.add(Document.for_object(@index, users(index: 1)))
      end

      def teardown
        @index.drop
      end

      def test_get_with_id
        finder = Document::Finder.new(@index, 1)

        assert_equal "#{@index.name}1", finder.find.document_id
      end

      def test_get_with_id_when_not_found
        assert_nil Document::Finder.new(@index, 4).find
      end
    end
  end
end
