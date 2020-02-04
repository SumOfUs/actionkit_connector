module ActionKitConnector
  module REST
    module Transaction
      def get_transaction(id)
        self.class.get("/transaction/#{id}/", prep_options({}))
      end

      def update_transaction(id, data)
        self.class.put("/transaction/#{id}/", prep_options(data))
      end
    end
  end
end
