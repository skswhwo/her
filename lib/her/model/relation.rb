module Her
  module Model
    class Relation
      attr_accessor :query_attrs

      # @private
      def initialize(parent)
        @parent = parent
        @query_attrs = {}
      end

      # Build a new resource
      def build(attrs = {})
        @parent.new(@query_attrs.merge(attrs))
      end

      # Add a query string parameter
      def where(attrs = {})
        return self if attrs.blank?
        self.clone.tap { |a| a.query_attrs = a.query_attrs.merge(attrs) }
      end
      alias :all :where

      # Bubble all methods to the fetched collection
      def method_missing(method, *args, &blk)
        fetch.send(method, *args, &blk)
      end

      # @private
      def nil?
        fetch.nil?
      end

      # @private
      def kind_of?(thing)
        fetch.kind_of?(thing)
      end

      # Fetch a collection of resources
      #
      # @example
      #   @users = User.all
      #   # Fetched via GET "/users"
      #
      # @example
      #   @users = User.where(:approved => 1).all
      #   # Fetched via GET "/users?approved=1"
      def fetch
        @_fetch ||= begin
          path = @parent.build_request_path(@query_attrs)
          @parent.request(@query_attrs.merge(:_method => :get, :_path => path)) do |parsed_data, response|
            @parent.new_collection(parsed_data)
          end
        end
      end

      # Create a resource and return it
      #
      # @example
      #   @user = User.create(:fullname => "Tobias Fünke")
      #   # Called via POST "/users/1" with `&fullname=Tobias+Fünke`
      #
      # @example
      #   @user = User.where(:email => "tobias@bluth.com").create(:fullname => "Tobias Fünke")
      #   # Called via POST "/users/1" with `&email=tobias@bluth.com&fullname=Tobias+Fünke`
      def create(params={})
        resource = @parent.new(@query_attrs.merge(params))
        resource.save

        resource
      end
    end
  end
end
